import Foundation

enum TestRepositoryError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case unreadableFile(String)
    case invalidJSON(String)
    case emptyRepository
    case invalidPackageName(String)
    case unknownDependency(package: String, dependency: String)
    case packageNotFound(String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Файл тестового репозитория не найден: \(path)"
        case .unreadableFile(let path):
            return "Не удалось прочитать тестовый репозиторий: \(path)"
        case .invalidJSON(let message):
            return "Некорректный JSON тестового репозитория: \(message)"
        case .emptyRepository:
            return "Тестовый репозиторий не содержит пакетов"
        case .invalidPackageName(let name):
            return "Некорректное имя тестового пакета: \(name)"
        case .unknownDependency(let package, let dependency):
            return "Пакет \(package) ссылается на отсутствующий пакет \(dependency)"
        case .packageNotFound(let name):
            return "Пакет \(name) отсутствует в тестовом репозитории"
        }
    }
}

struct TestRepository {
    private static let uppercaseAValue: UInt32 = 65
    private static let uppercaseZValue: UInt32 = 90

    private let packages: [String: [String]]

    init(fileAtPath path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw TestRepositoryError.fileNotFound(path)
        }

        let data: Data

        do {
            data = try Data(
                contentsOf: URL(fileURLWithPath: path)
            )
        } catch {
            throw TestRepositoryError.unreadableFile(path)
        }

        let decodedPackages: [String: [String]]

        do {
            decodedPackages = try JSONDecoder().decode(
                [String: [String]].self,
                from: data
            )
        } catch {
            throw TestRepositoryError.invalidJSON(
                error.localizedDescription
            )
        }

        guard !decodedPackages.isEmpty else {
            throw TestRepositoryError.emptyRepository
        }

        try Self.validate(decodedPackages)
        packages = decodedPackages
    }

    func fetchDirectDependencies(
        for packageName: String
    ) async throws -> PackageDependencies {
        guard let dependencyNames = packages[packageName] else {
            throw TestRepositoryError.packageNotFound(packageName)
        }

        let dependencies = dependencyNames
            .map {
                DirectDependency(
                    name: $0,
                    versionRequirement: "test"
                )
            }
            .sorted {
                $0.name.localizedStandardCompare($1.name)
                    == .orderedAscending
            }

        return PackageDependencies(
            packageName: packageName,
            packageVersion: "test",
            dependencies: dependencies
        )
    }

    private static func validate(
        _ packages: [String: [String]]
    ) throws {
        for (package, dependencies) in packages {
            guard isUppercaseLatin(package) else {
                throw TestRepositoryError.invalidPackageName(package)
            }

            for dependency in dependencies {
                guard isUppercaseLatin(dependency) else {
                    throw TestRepositoryError.invalidPackageName(
                        dependency
                    )
                }

                guard packages[dependency] != nil else {
                    throw TestRepositoryError.unknownDependency(
                        package: package,
                        dependency: dependency
                    )
                }
            }
        }
    }

    private static func isUppercaseLatin(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        return value.unicodeScalars.allSatisfy {
            $0.value >= uppercaseAValue &&
                $0.value <= uppercaseZValue
        }
    }
}