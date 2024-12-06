import MyMacro

@DynamicParameters
class SampleRequest {
    var command: String
    var duration: Int
    var subRequest: SubRequest
    var requests: [SubRequest]
    
    init(command: String, duration: Int, subRequest: SubRequest, requests: [SubRequest]) {
        self.command = command
        self.duration = duration
        self.subRequest = subRequest
        self.requests = requests
    }
}

@DynamicParameters
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
