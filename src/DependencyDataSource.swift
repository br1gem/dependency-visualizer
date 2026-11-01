import Foundation

enum DependencyDataSource {
    case npm(NPMRegistryClient)
    case test(TestRepository)

    func fetchDirectDependencies(
        for packageName: String
    ) async throws -> PackageDependencies {
        switch self {
        case .npm(let client):
            return try await client.fetchDirectDependencies(
                for: packageName
            )
        case .test(let repository):
            return try await repository.fetchDirectDependencies(
                for: packageName
            )
        }
    }
}