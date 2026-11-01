import Foundation

enum ApplicationError: Error, CustomStringConvertible {
    case testModeUnavailable

    var description: String {
        switch self {
        case .testModeUnavailable:
            return "Тестовый режим будет доступен на этапе 3"
        }
    }
}

let arguments = CommandLine.arguments

guard arguments.count <= 2 else {
    let executableName = arguments[0]
    print("Ошибка: указано слишком много аргументов.")
    print("Использование: \(executableName) [путь_к_config.yaml]")
    exit(1)
}

let configurationPath: String

if arguments.count == 2 {
    configurationPath = arguments[1]
} else {
    configurationPath = "config.yaml"
}

do {
    let values = try YAMLParser.parse(
        fileAtPath: configurationPath
    )

    let configuration = try Configuration(values: values)

    guard !configuration.testMode else {
        throw ApplicationError.testModeUnavailable
    }

    let client = NPMRegistryClient(
        repositoryURL: configuration.repository
    )

    let result = try await client.fetchDirectDependencies(
        for: configuration.packageName
    )

    print(
        "Прямые зависимости пакета " +
        "\(result.packageName)@\(result.packageVersion):"
    )

    if result.dependencies.isEmpty {
        print("Прямые зависимости отсутствуют.")
    } else {
        for dependency in result.dependencies {
            print(
                "- \(dependency.name): " +
                "\(dependency.versionRequirement)"
            )
        }
    }

    print("Всего зависимостей: \(result.dependencies.count)")
} catch let error as YAMLParserError {
    print("Ошибка конфигурационного файла:")
    print(error.description)
    exit(1)
} catch let error as ConfigurationError {
    print("Ошибка параметров конфигурации:")
    print(error.description)
    exit(1)
} catch let error as NPMRegistryError {
    print("Ошибка npm Registry:")
    print(error.description)
    exit(1)
} catch let error as ApplicationError {
    print("Ошибка приложения:")
    print(error.description)
    exit(1)
} catch {
    print("Неизвестная ошибка: \(error.localizedDescription)")
    exit(1)
}