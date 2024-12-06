import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct DynamicParametersPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DynamicParametersMacro.self
    ]
}

public struct DynamicParametersMacro: MemberMacro {
    struct MacroError: Error, CustomStringConvertible {
        let message: String
        var description: String { "MacroError: \(message)" }
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // クラスや構造体のメンバーを取得
        let members = declaration.memberBlock.members

        // メンバーを解析してプロパティリストを作成
        let parameterDecls = members.compactMap { member -> String? in
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = variableDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation?.type else {
                return nil
            }

            return try? generateParameter(for: pattern.identifier.text, type: typeAnnotation)
        }.joined(separator: ",\n")

        let cases = members.compactMap { member -> String? in
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = variableDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation?.type else {
                return nil
            }

            return try? generateCase(for: pattern.identifier.text, type: typeAnnotation)
        }

        return [
            """
            var parameters: [Parameter] {
                return [
                    \(raw: parameterDecls)
                ]
            }

            func updateParameters(_ parameters: [Parameter]) {
                for parameter in parameters {
                    switch parameter.key {
                    \(raw: cases.joined(separator: "\n"))
                    default:
                        break
                    }
                }
            }
            """
        ]
    }

    /// `parameters` の初期化部分を生成
    private static func generateParameter(for name: String, type: TypeSyntax) throws -> String {
        let typeName = type.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if typeName.hasPrefix("[") && typeName.hasSuffix("]") {
            // 配列型の場合
            let elementType = String(typeName.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines))
            return try generateArrayParameter(for: name, elementType: elementType)
        }

        // 通常の型の場合
        return try generateSimpleParameter(for: name, type: typeName)
    }

    /// 配列の `Parameter` 初期化部分を生成
    private static func generateArrayParameter(for name: String, elementType: String) throws -> String {
        switch elementType {
        case "String":
            return """
            Parameter(key: "\(name)", value: .arrayValue(\(name).map { .stringValue($0, defaultValue: $0) }, defaultValue: \(name).map { .stringValue($0, defaultValue: $0) }))
            """
        case "Int":
            return """
            Parameter(key: "\(name)", value: .arrayValue(\(name).map { .intValue($0, defaultValue: $0) }, defaultValue: \(name).map { .intValue($0, defaultValue: $0) }))
            """
        case "Float":
            return """
            Parameter(key: "\(name)", value: .arrayValue(\(name).map { .floatValue($0, defaultValue: $0) }, defaultValue: \(name).map { .floatValue($0, defaultValue: $0) }))
            """
        case "Double":
            return """
            Parameter(key: "\(name)", value: .arrayValue(\(name).map { .doubleValue($0, defaultValue: $0) }, defaultValue: \(name).map { .doubleValue($0, defaultValue: $0) }))
            """
        case "Bool":
            return """
            Parameter(key: "\(name)", value: .arrayValue(\(name).map { .boolValue($0, defaultValue: $0) }, defaultValue: \(name).map { .boolValue($0, defaultValue: $0) }))
            """
        default:
            // カスタム型の場合
            return """
            Parameter(key: "\(name)", value: .arrayValue(\(name).map { .structValue($0.parameters, defaultValue: $0.parameters) }, defaultValue: \(name).map { .structValue($0.parameters, defaultValue: $0.parameters) }))
            """
        }
    }

    /// 単純型の `Parameter` 初期化部分を生成
    private static func generateSimpleParameter(for name: String, type: String) throws -> String {
        switch type {
        case "String":
            return "Parameter(key: \"\(name)\", value: .stringValue(\(name), defaultValue: \(name)))"
        case "String?":
            return "Parameter(key: \"\(name)\", value: .optionalStringValue(\(name), defaultValue: \(name)))"
        case "Int":
            return "Parameter(key: \"\(name)\", value: .intValue(\(name), defaultValue: \(name)))"
        case "Int?":
            return "Parameter(key: \"\(name)\", value: .optionalIntValue(\(name), defaultValue: \(name)))"
        case "Float":
            return "Parameter(key: \"\(name)\", value: .floatValue(\(name), defaultValue: \(name)))"
        case "Float?":
            return "Parameter(key: \"\(name)\", value: .optionalFloatValue(\(name), defaultValue: \(name)))"
        case "Double":
            return "Parameter(key: \"\(name)\", value: .doubleValue(\(name), defaultValue: \(name)))"
        case "Double?":
            return "Parameter(key: \"\(name)\", value: .optionalDoubleValue(\(name), defaultValue: \(name)))"
        case "Bool":
            return "Parameter(key: \"\(name)\", value: .boolValue(\(name), defaultValue: \(name)))"
        case "Bool?":
            return "Parameter(key: \"\(name)\", value: .optionalBoolValue(\(name), defaultValue: \(name)))"
        default:
            return "Parameter(key: \"\(name)\", value: .structValue(\(name).parameters, defaultValue: \(name).parameters))"
        }
    }

    /// `case` 文を生成
    private static func generateCase(for name: String, type: TypeSyntax) throws -> String {
        let typeName = type.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if typeName.hasPrefix("[") && typeName.hasSuffix("]") {
            // 配列型の場合
            let elementType = String(typeName.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines))
            return try generateArrayCase(for: name, elementType: elementType)
        }

        switch typeName {
        case "String", "Int", "Float", "Double", "Bool":
            return """
            case "\(name)":
                if case let .\(simpleTypeToValueType(typeName))(value, _) = parameter.value {
                    \(name) = value
                }
            """
        case "String?", "Int?", "Float?", "Double?", "Bool?":
            return """
            case "\(name)":
                if case let .\(simpleTypeToValueType(typeName))(value, _) = parameter.value {
                    \(name) = value
                }
            """
        default:
            return """
            case "\(name)":
                if case let .structValue(parameters, _) = parameter.value {
                    \(name).updateParameters(parameters)
                }
            """
        }
    }

    /// 配列の `case` 文を生成
    private static func generateArrayCase(for name: String, elementType: String) throws -> String {
        switch elementType {
        case "String", "Int", "Float", "Double", "Bool":
            return """
            case "\(name)":
                if case let .arrayValue(values, _) = parameter.value {
                    \(name) = values.map { $0 }
                }
            """
        default:
            return """
            case "\(name)":
                if case let .arrayValue(values, _) = parameter.value {
                    \(name) = values.map { \(elementType)(parameters: $0) }
                }
            """
        }
    }

    /// 単純型を `ValueType` 名に変換
    private static func simpleTypeToValueType(_ typeName: String) -> String {
        switch typeName {
        case "String": return "stringValue"
        case "String?": return "optionalStringValue"
        case "Int": return "intValue"
        case "Int?": return "optionalIntValue"
        case "Float": return "floatValue"
        case "Float?": return "optionalFloatValue"
        case "Double": return "doubleValue"
        case "Double?": return "optionalDoubleValue"
        case "Bool": return "boolValue"
        case "Bool?": return "optionalBoolValue"
        default: return "unknownValue"
        }
    }
}
