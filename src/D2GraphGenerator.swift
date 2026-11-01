import Foundation

struct D2GraphGenerator {
    func generate(
        from graph: DependencyGraph
    ) -> String {
        let packages = graph.allPackages
        let nodeIdentifiers = makeNodeIdentifiers(
            packages: packages
        )

        var lines: [String] = [
            "direction: right",
            ""
        ]

        for package in packages {
            guard let identifier =
                nodeIdentifiers[package]
            else {
                continue
            }

            let label = makeNodeLabel(
                package: package,
                version: graph.packageVersions[package]
            )

            lines.append(
                "\(identifier): \"\(escape(label))\" {"
            )
            lines.append("  shape: rectangle")

            if package == graph.rootPackage {
                lines.append("  style.fill: \"#dbeafe\"")
                lines.append("  style.stroke: \"#2563eb\"")
                lines.append("  style.stroke-width: 2")
            }

            lines.append("}")
        }

        lines.append("")

        for package in packages {
            guard let sourceIdentifier =
                nodeIdentifiers[package]
            else {
                continue
            }

            let dependencies = graph.dependencies(
                of: package
            ).sorted {
                $0.name.localizedStandardCompare($1.name)
                    == .orderedAscending
            }

            for dependency in dependencies {
                guard let targetIdentifier =
                    nodeIdentifiers[dependency.name]
                else {
                    continue
                }

                let edge = makeEdge(
                    source: sourceIdentifier,
                    target: targetIdentifier,
                    versionRequirement:
                        dependency.versionRequirement
                )

                lines.append(edge)
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func makeNodeIdentifiers(
        packages: [String]
    ) -> [String: String] {
        var identifiers: [String: String] = [:]

        for (index, package) in packages.enumerated() {
            identifiers[package] = "node_\(index)"
        }

        return identifiers
    }

    private func makeNodeLabel(
        package: String,
        version: String?
    ) -> String {
        guard
            let version,
            version != "test"
        else {
            return package
        }

        return "\(package)@\(version)"
    }

    private func makeEdge(
        source: String,
        target: String,
        versionRequirement: String
    ) -> String {
        let connection = "\(source) -> \(target)"

        guard versionRequirement != "test" else {
            return connection
        }

        let label = escape(versionRequirement)

        return "\(connection): \"\(label)\""
    }

    private func escape(
        _ value: String
    ) -> String {
        value
            .replacingOccurrences(
                of: "\\",
                with: "\\\\"
            )
            .replacingOccurrences(
                of: "\"",
                with: "\\\""
            )
            .replacingOccurrences(
                of: "\n",
                with: "\\n"
            )
    }
}
