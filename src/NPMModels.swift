import Foundation

struct NPMMetadata: Decodable {
    let name: String
    let distTags: [String: String]
    let versions: [String: NPMPackageVersion]

    enum CodingKeys: String, CodingKey {
        case name
        case distTags = "dist-tags"
        case versions
    }
}

struct NPMPackageVersion: Decodable {
    let name: String
    let version: String
    let dependencies: [String: String]?
}

struct DirectDependency: Equatable {
    let name: String
    let versionRequirement: String
}

struct PackageDependencies {
    let packageName: String
    let packageVersion: String
    let dependencies: [DirectDependency]
}