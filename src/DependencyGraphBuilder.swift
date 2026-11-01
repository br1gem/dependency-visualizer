import Foundation

struct DependencyGraphBuilder {
    private let dataSource: DependencyDataSource
    private let filterSubstring: String

    init(
        dataSource: DependencyDataSource,
        filterSubstring: String
    ) {
        self.dataSource = dataSource
        self.filterSubstring = filterSubstring
    }

    func buildGraph(
        from rootPackage: String
    ) async throws -> DependencyGraph {
        var graph = DependencyGraph(
            rootPackage: rootPackage
        )

        var queue: [String] = [rootPackage]
        var discoveredPackages: Set<String> = [rootPackage]
        var currentIndex = 0

        while currentIndex < queue.count {
            let currentPackage = queue[currentIndex]
            currentIndex += 1

            let result = try await dataSource
                .fetchDirectDependencies(
                    for: currentPackage
                )

            let filteredDependencies = result.dependencies
                .filter {
                    !$0.name.contains(filterSubstring)
                }

            graph.record(
                package: currentPackage,
                version: result.packageVersion,
                dependencies: filteredDependencies
            )

            for dependency in filteredDependencies {
                if discoveredPackages.insert(
                    dependency.name
                ).inserted {
                    queue.append(dependency.name)
                }
            }
        }

        return graph
    }
}
