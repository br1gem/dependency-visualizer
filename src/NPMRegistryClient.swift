import Foundation

enum NPMRegistryError: Error, CustomStringConvertible {
    case invalidRepositoryURL(String)
    case invalidPackageName(String)
    case requestFailed(String)
    case invalidResponse
    case packageNotFound(String)
    case httpError(Int)
    case invalidMetadata(String)
    case missingLatestTag(String)
    case missingLatestVersion(String)

    var description: String {
        switch self {
        case .invalidRepositoryURL(let value):
            return "Некорректный URL npm-репозитория: \(value)"
        case .invalidPackageName(let value):
            return "Некорректное имя npm-пакета: \(value)"
        case .requestFailed(let message):
            return "Не удалось выполнить запрос: \(message)"
        case .invalidResponse:
            return "Репозиторий вернул некорректный HTTP-ответ"
        case .packageNotFound(let name):
            return "Пакет \(name) не найден в репозитории"
        case .httpError(let statusCode):
            return "Репозиторий вернул HTTP-ошибку \(statusCode)"
        case .invalidMetadata(let message):
            return "Не удалось разобрать метаданные пакета: \(message)"
        case .missingLatestTag(let name):
            return "У пакета \(name) отсутствует тег latest"
        case .missingLatestVersion(let version):
            return "В метаданных отсутствует версия \(version)"
        }
    }
}

struct NPMRegistryClient {
    private let repositoryURL: String

    init(repositoryURL: String) {
        self.repositoryURL = repositoryURL
    }

    func fetchDirectDependencies(
        for packageName: String
    ) async throws -> PackageDependencies {
        let url = try makePackageURL(packageName: packageName)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "application/vnd.npm.install-v1+json",
            forHTTPHeaderField: "Accept"
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NPMRegistryError.requestFailed(
                error.localizedDescription
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NPMRegistryError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw NPMRegistryError.packageNotFound(packageName)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NPMRegistryError.httpError(httpResponse.statusCode)
        }

        let metadata: NPMMetadata

        do {
            metadata = try JSONDecoder().decode(
                NPMMetadata.self,
                from: data
            )
        } catch {
            throw NPMRegistryError.invalidMetadata(
                error.localizedDescription
            )
        }

        guard let latestVersion = metadata.distTags["latest"] else {
            throw NPMRegistryError.missingLatestTag(packageName)
        }

        guard let packageVersion = metadata.versions[latestVersion] else {
            throw NPMRegistryError.missingLatestVersion(latestVersion)
        }

        let dependencies = packageVersion.dependencies ?? [:]

        let directDependencies = dependencies
            .map {
                DirectDependency(
                    name: $0.key,
                    versionRequirement: $0.value
                )
            }
            .sorted {
                $0.name.localizedStandardCompare($1.name)
                    == .orderedAscending
            }

        return PackageDependencies(
            packageName: metadata.name,
            packageVersion: packageVersion.version,
            dependencies: directDependencies
        )
    }

    private func makePackageURL(
        packageName: String
    ) throws -> URL {
        guard !packageName.isEmpty else {
            throw NPMRegistryError.invalidPackageName(packageName)
        }

        guard let baseURL = URL(string: repositoryURL) else {
            throw NPMRegistryError.invalidRepositoryURL(repositoryURL)
        }

        guard
            baseURL.scheme == "http" || baseURL.scheme == "https",
            baseURL.host != nil
        else {
            throw NPMRegistryError.invalidRepositoryURL(repositoryURL)
        }

        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/")

        guard let encodedName = packageName.addingPercentEncoding(
            withAllowedCharacters: allowedCharacters
        ) else {
            throw NPMRegistryError.invalidPackageName(packageName)
        }

        let base = repositoryURL.hasSuffix("/")
            ? String(repositoryURL.dropLast())
            : repositoryURL

        guard let packageURL = URL(
            string: "\(base)/\(encodedName)"
        ) else {
            throw NPMRegistryError.invalidPackageName(packageName)
        }

        return packageURL
    }
}
