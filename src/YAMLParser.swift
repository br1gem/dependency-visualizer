import Foundation

enum YAMLParserError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case unreadableFile(String)
    case invalidLine(Int, String)
    case emptyKey(Int)
    case emptyValue(Int, String)
    case duplicateKey(Int, String)
    case unknownKey(Int, String)
    case invalidQuotes(Int, String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Конфигурационный файл не найден: \(path)"
        case .unreadableFile(let path):
            return "Не удалось прочитать конфигурационный файл: \(path)"
        case .invalidLine(let line, let content):
            return "Ошибка YAML в строке \(line): \(content)"
        case .emptyKey(let line):
            return "Пустой ключ в строке \(line)"
        case .emptyValue(let line, let key):
            return "Пустое значение параметра \(key) в строке \(line)"
        case .duplicateKey(let line, let key):
            return "Повторяющийся параметр \(key) в строке \(line)"
        case .unknownKey(let line, let key):
            return "Неизвестный параметр \(key) в строке \(line)"
        case .invalidQuotes(let line, let value):
            return "Незакрытые кавычки в строке \(line): \(value)"
        }
    }
}

struct YAMLParser {
    private static let allowedKeys: Set<String> = [
        "package_name",
        "repository",
        "test_mode",
        "output_file",
        "filter_substring"
    ]

    static func parse(fileAtPath path: String) throws -> [String: String] {
        guard FileManager.default.fileExists(atPath: path) else {
            throw YAMLParserError.fileNotFound(path)
        }

        guard let content = try? String(
            contentsOfFile: path,
            encoding: .utf8
        ) else {
            throw YAMLParserError.unreadableFile(path)
        }

        var values: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)

        for (index, originalLine) in lines.enumerated() {
            let lineNumber = index + 1
            let line = originalLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            let pair = try parseLine(line, lineNumber: lineNumber)
            let key = pair.key
            let value = pair.value

            guard allowedKeys.contains(key) else {
                throw YAMLParserError.unknownKey(lineNumber, key)
            }

            guard values[key] == nil else {
                throw YAMLParserError.duplicateKey(lineNumber, key)
            }

            values[key] = value
        }

        return values
    }

    private static func parseLine(
        _ line: String,
        lineNumber: Int
    ) throws -> (key: String, value: String) {
        let parts = line.split(
            separator: ":",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        guard parts.count == 2 else {
            throw YAMLParserError.invalidLine(lineNumber, line)
        }

        let key = String(parts[0])
            .trimmingCharacters(in: .whitespaces)

        let rawValue = String(parts[1])
            .trimmingCharacters(in: .whitespaces)

        guard !key.isEmpty else {
            throw YAMLParserError.emptyKey(lineNumber)
        }

        guard !rawValue.isEmpty else {
            throw YAMLParserError.emptyValue(lineNumber, key)
        }

        let value = try removeQuotes(
            from: rawValue,
            lineNumber: lineNumber
        )

        guard !value.isEmpty else {
            throw YAMLParserError.emptyValue(lineNumber, key)
        }

        return (key, value)
    }

    private static func removeQuotes(
        from value: String,
        lineNumber: Int
    ) throws -> String {
        let startsWithDoubleQuote = value.hasPrefix("\"")
        let endsWithDoubleQuote = value.hasSuffix("\"")
        let startsWithSingleQuote = value.hasPrefix("'")
        let endsWithSingleQuote = value.hasSuffix("'")

        if startsWithDoubleQuote || endsWithDoubleQuote {
            guard startsWithDoubleQuote && endsWithDoubleQuote else {
                throw YAMLParserError.invalidQuotes(lineNumber, value)
            }
            return String(value.dropFirst().dropLast())
        }

        if startsWithSingleQuote || endsWithSingleQuote {
            guard startsWithSingleQuote && endsWithSingleQuote else {
                throw YAMLParserError.invalidQuotes(lineNumber, value)
            }
            return String(value.dropFirst().dropLast())
        }

        return value
    }
}