import Foundation

enum ConfigurationError: Error, CustomStringConvertible {
    case missingParameter(String)
    case emptyParameter(String)
    case invalidBoolean(String)
    case invalidRepositoryURL(String)
    case testRepositoryNotFound(String)
    case invalidOutputFile(String)

    var description: String {
        switch self {
        case .missingParameter(let name):
            return "Отсутствует обязательный параметр: \(name)"
        case .emptyParameter(let name):
            return "Параметр \(name) не может быть пустым"
        case .invalidBoolean(let value):
            return "Параметр test_mode должен содержать true или false, получено: \(value)"
        case .invalidRepositoryURL(let value):
            return "Некорректный URL репозитория: \(value)"
        case .testRepositoryNotFound(let path):
            return "Файл тестового репозитория не найден: \(path)"
        case .invalidOutputFile(let value):
            return "Имя выходного файла должно оканчиваться на .svg: \(value)"
        }
    }
}

struct Configuration {
    let packageName: String
    let repository: String
    let testMode: Bool
    let outputFile: String
    let filterSubstring: String

    init(values: [String: String]) throws {
        packageName = try Self.requiredValue(
            named: "package_name",
            in: values
        )

        repository = try Self.requiredValue(
            named: "repository",
            in: values
        )

        let testModeValue = try Self.requiredValue(
            named: "test_mode",
            in: values
        )

        testMode = try Self.parseBoolean(testModeValue)

        outputFile = try Self.requiredValue(
            named: "output_file",
            in: values
        )

        filterSubstring = try Self.requiredValue(
            named: "filter_substring",
            in: values
        )

        try Self.validateRepository(
            repository,
            testMode: testMode
        )

        guard outputFile.hasSuffix(".svg") else {
            throw ConfigurationError.invalidOutputFile(outputFile)
        }
    }

    private static func requiredValue(
        named name: String,
        in values: [String: String]
    ) throws -> String {
        guard let value = values[name] else {
            throw ConfigurationError.missingParameter(name)
        }

        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ConfigurationError.emptyParameter(name)
        }

        return value
    }

    private static func parseBoolean(_ value: String) throws -> Bool {
        switch value.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            throw ConfigurationError.invalidBoolean(value)
        }
    }

    private static func validateRepository(
        _ value: String,
        testMode: Bool
    ) throws {
        if testMode {
            guard FileManager.default.fileExists(atPath: value) else {
                throw ConfigurationError.testRepositoryNotFound(value)
            }
            return
        }

        guard
            let components = URLComponents(string: value),
            components.scheme == "http" || components.scheme == "https",
            components.host != nil
        else {
            throw ConfigurationError.invalidRepositoryURL(value)
        }
    }

    func printParameters() {
        print("package_name: \(packageName)")
        print("repository: \(repository)")
        print("test_mode: \(testMode)")
        print("output_file: \(outputFile)")
        print("filter_substring: \(filterSubstring)")
    }
}