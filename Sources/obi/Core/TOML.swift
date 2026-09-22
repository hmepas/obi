import Foundation

enum TOMLValue: Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([TOMLValue])
}

struct TOMLError: Error, CustomStringConvertible {
    let line: Int
    let message: String
    var description: String { "line \(line): \(message)" }
}

/// Strict TOML subset: `key = value`, `[a.b]` tables, `#` comments, double-quoted strings,
/// integers, booleans, single-line arrays. Result keys are dotted paths (`widgets.cpu.threshold`).
enum TOML {
    static func parse(_ text: String) throws -> [String: TOMLValue] {
        var result: [String: TOMLValue] = [:]
        var table = ""
        for (i, raw) in text.components(separatedBy: "\n").enumerated() {
            let lineNo = i + 1
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("[") {
                guard let close = line.firstIndex(of: "]") else {
                    throw TOMLError(line: lineNo, message: "unterminated table header")
                }
                let name = line[line.index(after: line.startIndex)..<close].trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty, name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" || $0 == "." }) else {
                    throw TOMLError(line: lineNo, message: "bad table name '\(name)'")
                }
                try expectEnd(line, from: line.index(after: close), lineNo)
                table = name
                continue
            }
            let key: String
            var scanner: Scanner
            if line.hasPrefix("\"") {
                // Quoted key: "Wispr Flow" = "..."
                scanner = Scanner(line: line, pos: line.startIndex, lineNo: lineNo)
                key = try scanner.string()
                scanner.skipSpace()
                guard scanner.current == "=" else { throw TOMLError(line: lineNo, message: "expected '=' after quoted key") }
                scanner.pos = line.index(after: scanner.pos)
            } else {
                guard let eq = line.firstIndex(of: "=") else {
                    throw TOMLError(line: lineNo, message: "expected 'key = value'")
                }
                key = line[..<eq].trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty, key.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }) else {
                    throw TOMLError(line: lineNo, message: "bad key '\(key)'")
                }
                scanner = Scanner(line: line, pos: line.index(after: eq), lineNo: lineNo)
            }
            let value = try scanner.value()
            try scanner.end()
            let path = table.isEmpty ? key : "\(table).\(key)"
            if result[path] != nil { throw TOMLError(line: lineNo, message: "duplicate key '\(path)'") }
            result[path] = value
        }
        return result
    }

    private static func expectEnd(_ line: String, from: String.Index, _ lineNo: Int) throws {
        let rest = line[from...].trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty && !rest.hasPrefix("#") {
            throw TOMLError(line: lineNo, message: "unexpected '\(rest)'")
        }
    }

    private struct Scanner {
        let line: String
        var pos: String.Index
        let lineNo: Int

        var current: Character? { pos < line.endIndex ? line[pos] : nil }

        mutating func skipSpace() {
            while let c = current, c == " " || c == "\t" { pos = line.index(after: pos) }
        }

        mutating func value() throws -> TOMLValue {
            skipSpace()
            guard let c = current else { throw TOMLError(line: lineNo, message: "missing value") }
            switch c {
            case "\"": return .string(try string())
            case "[": return .array(try array())
            case "-", "0"..."9": return .int(try integer())
            default:
                if line[pos...].hasPrefix("true") { pos = line.index(pos, offsetBy: 4); return .bool(true) }
                if line[pos...].hasPrefix("false") { pos = line.index(pos, offsetBy: 5); return .bool(false) }
                throw TOMLError(line: lineNo, message: "unsupported value at '\(line[pos...].prefix(10))'")
            }
        }

        mutating func string() throws -> String {
            pos = line.index(after: pos)
            var out = ""
            while let c = current {
                pos = line.index(after: pos)
                switch c {
                case "\"": return out
                case "\\":
                    guard let e = current else { break }
                    pos = line.index(after: pos)
                    switch e {
                    case "n": out.append("\n")
                    case "t": out.append("\t")
                    case "\"": out.append("\"")
                    case "\\": out.append("\\")
                    default: throw TOMLError(line: lineNo, message: "bad escape '\\\(e)'")
                    }
                default: out.append(c)
                }
            }
            throw TOMLError(line: lineNo, message: "unterminated string")
        }

        mutating func integer() throws -> Int {
            let start = pos
            if current == "-" { pos = line.index(after: pos) }
            while let c = current, c.isNumber || c == "_" { pos = line.index(after: pos) }
            let text = line[start..<pos].replacingOccurrences(of: "_", with: "")
            guard let v = Int(text) else { throw TOMLError(line: lineNo, message: "bad integer '\(text)'") }
            return v
        }

        mutating func array() throws -> [TOMLValue] {
            pos = line.index(after: pos)
            var items: [TOMLValue] = []
            while true {
                skipSpace()
                guard let c = current else { throw TOMLError(line: lineNo, message: "unterminated array") }
                if c == "]" { pos = line.index(after: pos); return items }
                items.append(try value())
                skipSpace()
                switch current {
                case ",": pos = line.index(after: pos)
                case "]": continue
                default: throw TOMLError(line: lineNo, message: "expected ',' or ']' in array")
                }
            }
        }

        mutating func end() throws {
            skipSpace()
            if let c = current, c != "#" {
                throw TOMLError(line: lineNo, message: "unexpected '\(line[pos...])'")
            }
        }
    }
}
