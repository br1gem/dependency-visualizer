import Foundation

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

    print("Параметры конфигурации:")
    configuration.printParameters()
} catch let error as YAMLParserError {
    print("Ошибка конфигурационного файла:")
    print(error.description)
    exit(1)
} catch let error as ConfigurationError {
    print("Ошибка параметров конфигурации:")
    print(error.description)
    exit(1)
} catch {
    print("Неизвестная ошибка: \(error.localizedDescription)")
    exit(1)
}