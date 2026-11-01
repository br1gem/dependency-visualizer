import Foundation

struct LoadOrderResult {
    let orderedPackages: [String]
    let unresolvedPackages: [String]

    var isComplete: Bool {
        unresolvedPackages.isEmpty
    }

    func printResult() {
        if isComplete {
            let order = orderedPackages.joined(
                separator: " -> "
            )

            print("Порядок загрузки зависимостей:")
            print(order)
            return
        }

        print(
            "Полный порядок загрузки определить невозможно: " +
            "граф содержит цикл."
        )

        if !orderedPackages.isEmpty {
            let partialOrder = orderedPackages.joined(
                separator: " -> "
            )

            print("Определенная часть порядка:")
            print(partialOrder)
        }

        let unresolved = unresolvedPackages.joined(
            separator: ", "
        )

        print("Не удалось упорядочить пакеты:")
        print(unresolved)
    }
}

struct DependencyLoadOrder {
    static func calculate(
        for graph: DependencyGraph
    ) -> LoadOrderResult {
        let packages = graph.allPackages

        var remainingDependencies: [String: Int] = [:]
        var dependents: [String: Set<String>] = [:]

        for package in packages {
            let dependencyNames = Set(
                graph.dependencies(of: package).map(\.name)
            )

            remainingDependencies[package] =
                dependencyNames.count

            for dependency in dependencyNames {
                dependents[dependency, default: []]
                    .insert(package)
            }
        }

        var availablePackages = packages.filter {
            remainingDependencies[$0] == 0
        }

        availablePackages.sort(
            by: comparePackageNames
        )

        var orderedPackages: [String] = []
        var processedPackages: Set<String> = []

        while !availablePackages.isEmpty {
            let package = availablePackages.removeFirst()

            guard processedPackages.insert(package).inserted else {
                continue
            }

            orderedPackages.append(package)

            let packageDependents = (
                dependents[package] ?? []
            ).sorted(
                by: comparePackageNames
            )

            for dependent in packageDependents {
                guard let count =
                    remainingDependencies[dependent]
                else {
                    continue
                }

                let updatedCount = count - 1
                remainingDependencies[dependent] =
                    updatedCount

                if updatedCount == 0 {
                    availablePackages.append(dependent)
                    availablePackages.sort(
                        by: comparePackageNames
                    )
                }
            }
        }

        let unresolvedPackages = packages.filter {
            !processedPackages.contains($0)
        }

        return LoadOrderResult(
            orderedPackages: orderedPackages,
            unresolvedPackages: unresolvedPackages
        )
    }

    private static func comparePackageNames(
        _ first: String,
        _ second: String
    ) -> Bool {
        first.localizedStandardCompare(second)
            == .orderedAscending
    }
}
