import Foundation

struct DependencyGraph {
    let rootPackage: String

    private(set) var adjacencyList: [
        String: [DirectDependency]
    ] = [:]

    private(set) var packageVersions: [
        String: String
    ] = [:]

    private(set) var traversalOrder: [String] = []

    mutating func record(
        package: String,
        version: String,
        dependencies: [DirectDependency]
    ) {
        if adjacencyList[package] == nil {
            traversalOrder.append(package)
        }

        adjacencyList[package] = dependencies
        packageVersions[package] = version
    }

    func dependencies(
        of package: String
    ) -> [DirectDependency] {
        adjacencyList[package] ?? []
    }

    var allPackages: [String] {
        var packages = Set(adjacencyList.keys)

        for dependencies in adjacencyList.values {
            for dependency in dependencies {
                packages.insert(dependency.name)
            }
        }

        packages.insert(rootPackage)

        return packages.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    var packageCount: Int {
        allPackages.count
    }

    var dependencyCount: Int {
        adjacencyList.values.reduce(0) {
            $0 + $1.count
        }
    }

    func printTraversalOrder() {
        let order = traversalOrder.joined(separator: " -> ")
        print("Порядок обхода BFS: \(order)")
    }

    func printAdjacencyList() {
        print("Граф зависимостей:")

        for package in allPackages {
            let dependencyNames = dependencies(of: package)
                .map(\.name)
                .sorted {
                    $0.localizedStandardCompare($1)
                        == .orderedAscending
                }

            if dependencyNames.isEmpty {
                print("\(package) -> нет зависимостей")
            } else {
                print(
                    "\(package) -> " +
                    dependencyNames.joined(separator: ", ")
                )
            }
        }

        print("Всего пакетов: \(packageCount)")
        print("Всего связей: \(dependencyCount)")
    }
}