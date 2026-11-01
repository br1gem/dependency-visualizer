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
    let dataSource: DependencyDataSource

    if configuration.testMode {
        let testRepository = try TestRepository(
            fileAtPath: configuration.repository
        )

        dataSource = .test(testRepository)
    } else {
        let npmClient = NPMRegistryClient(
            repositoryURL: configuration.repository
        )

        dataSource = .npm(npmClient)
    }

    let graphBuilder = DependencyGraphBuilder(
        dataSource: dataSource,
        filterSubstring: configuration.filterSubstring
    )

    let graph = try await graphBuilder.buildGraph(
        from: configuration.packageName
    )

    print("Корневой пакет: \(configuration.packageName)")
    print(
        "Фильтр пакетов: " +
        configuration.filterSubstring
    )
    print()

    graph.printTraversalOrder()
    print()

    graph.printAdjacencyList()
    print()

    let loadOrder = DependencyLoadOrder.calculate(
        for: graph
    )

    loadOrder.printResult()
    print()

    let d2Generator = D2GraphGenerator()
    let d2Source = d2Generator.generate(
        from: graph
    )

    print("Описание графа на языке D2:")
    print(d2Source, terminator: "")
    print()

    let renderer = D2Renderer()

    try renderer.render(
        source: d2Source,
        outputPath: configuration.outputFile
    )

    print(
        "SVG-файл сохранен: " +
        configuration.outputFile
    )
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
} catch let error as TestRepositoryError {
    print("Ошибка тестового репозитория:")
    print(error.description)
    exit(1)
} catch let error as D2RendererError {
    print("Ошибка визуализации:")
    print(error.description)
    exit(1)
} catch {
    print("Неизвестная ошибка: \(error.localizedDescription)")
    exit(1)
}