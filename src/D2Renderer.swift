import Foundation

enum D2RendererError: Error, CustomStringConvertible {
    case cannotCreateDirectory(String)
    case cannotWriteSource(String)
    case cannotStartD2(String)
    case d2NotFound
    case renderingFailed(code: Int32, message: String)
    case outputFileNotCreated(String)

    var description: String {
        switch self {
        case .cannotCreateDirectory(let path):
            return "Не удалось создать папку: \(path)"
        case .cannotWriteSource(let path):
            return "Не удалось сохранить временный D2-файл: \(path)"
        case .cannotStartD2(let message):
            return "Не удалось запустить D2: \(message)"
        case .d2NotFound:
            return "D2 CLI не найден. Установите его командой: brew install d2"
        case .renderingFailed(let code, let message):
            return "D2 завершился с кодом \(code): \(message)"
        case .outputFileNotCreated(let path):
            return "SVG-файл не был создан: \(path)"
        }
    }
}

struct D2Renderer {
    private let fileManager = FileManager.default

    func render(
        source: String,
        outputPath: String
    ) throws {
        let projectDirectory = fileManager
            .currentDirectoryPath

        let buildDirectory = URL(
            fileURLWithPath: projectDirectory
        )
        .appendingPathComponent(".build")
        .appendingPathComponent("d2")

        try createDirectory(buildDirectory)

        let sourceURL = buildDirectory
            .appendingPathComponent(
                "graph-\(UUID().uuidString).d2"
            )

        defer {
            try? fileManager.removeItem(
                at: sourceURL
            )
        }

        do {
            try source.write(
                to: sourceURL,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            throw D2RendererError.cannotWriteSource(
                sourceURL.path
            )
        }

        let outputURL = makeAbsoluteURL(
            path: outputPath,
            projectDirectory: projectDirectory
        )

        try createDirectory(
            outputURL.deletingLastPathComponent()
        )

        let process = Process()
        let errorPipe = Pipe()

        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/env"
        )

        process.arguments = [
            "d2",
            sourceURL.path,
            outputURL.path
        ]

        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw D2RendererError.cannotStartD2(
                error.localizedDescription
            )
        }

        process.waitUntilExit()

        let errorData = errorPipe
            .fileHandleForReading
            .readDataToEndOfFile()

        let errorMessage = String(
            data: errorData,
            encoding: .utf8
        )?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

        if process.terminationStatus == 127 {
            throw D2RendererError.d2NotFound
        }

        guard process.terminationStatus == 0 else {
            throw D2RendererError.renderingFailed(
                code: process.terminationStatus,
                message: errorMessage
            )
        }

        guard fileManager.fileExists(
            atPath: outputURL.path
        ) else {
            throw D2RendererError.outputFileNotCreated(
                outputURL.path
            )
        }
    }

    private func createDirectory(
        _ directory: URL
    ) throws {
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw D2RendererError.cannotCreateDirectory(
                directory.path
            )
        }
    }

    private func makeAbsoluteURL(
        path: String,
        projectDirectory: String
    ) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }

        return URL(
            fileURLWithPath: projectDirectory
        )
        .appendingPathComponent(path)
    }
}
