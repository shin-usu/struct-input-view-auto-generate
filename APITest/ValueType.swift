import SwiftUI

enum ValueType {
    case intValue(Int, defaultValue: Int)
    case optionalIntValue(Int?, defaultValue: Int?)
    case floatValue(Float, defaultValue: Float)
    case optionalFloatValue(Float?, defaultValue: Float?)
    case doubleValue(Double, defaultValue: Double)
    case optionalDoubleValue(Double?, defaultValue: Double?)
    case stringValue(String, defaultValue: String)
    case optionalStringValue(String?, defaultValue: String?)
    case boolValue(Bool, defaultValue: Bool)
    case optionalBoolValue(Bool?, defaultValue: Bool?)
    case arrayValue([ValueType], defaultValue: [ValueType])
    case structValue([Parameter], defaultValue: [Parameter])
}

struct Parameter {
    var key: String
    var value: ValueType
}

protocol DynamicParameters {
    var parameters: [Parameter] { get }
    mutating func updateParameters(_ parameters: [Parameter])
}

class SampleRequest {
    var command: String
    var duration: Int
    var subRequest: SubRequest
    
    init(command: String, duration: Int, subRequest: SubRequest) {
        self.command = command
        self.duration = duration
        self.subRequest = subRequest
    }
}

class SubRequest {
    var name: String
    var success: Bool
    var subTitle: String?
    
    init(name: String, success: Bool, subTitle: String? = nil) {
        self.name = name
        self.success = success
        self.subTitle = subTitle
    }
}

extension SampleRequest: DynamicParameters {
    var parameters: [Parameter] {
        [
            .init(key: "command", value: .stringValue(command, defaultValue: command)),
            .init(key: "duration", value: .intValue(duration, defaultValue: duration)),
            .init(key: "subRequest", value: .structValue(subRequest.parameters, defaultValue: subRequest.parameters)),
        ]
    }
    
    func updateParameters(_ parameters: [Parameter]) {
        for parameter in parameters {
            switch parameter.key {
            case "command":
                if case let .stringValue(value, _) = parameter.value {
                    command = value
                }
            case "duration":
                if case let .intValue(value, _) = parameter.value {
                    duration = value
                }
            case "subRequest":
                if case let .structValue(value, _) = parameter.value {
                    subRequest.updateParameters(value)
                }
            default:
                break
            }
        }
    }
}

extension SubRequest: DynamicParameters {
    var parameters: [Parameter] {
        [
            .init(key: "name", value: .stringValue(name, defaultValue: name)),
            .init(key: "success", value: .boolValue(success, defaultValue: success)),
            .init(key: "subTitle", value: .optionalStringValue(subTitle, defaultValue: subTitle)),
        ]
    }
    
    func updateParameters(_ parameters: [Parameter]) {
        for parameter in parameters {
            switch parameter.key {
            case "name":
                if case let .stringValue(value, _) = parameter.value {
                    name = value
                }
            case "success":
                if case let .boolValue(value, _) = parameter.value {
                    success = value
                }
            case "subTitle":
                if case let .optionalStringValue(value, _) = parameter.value {
                    subTitle = value
                }
            default:
                break
            }
        }
    }
}
