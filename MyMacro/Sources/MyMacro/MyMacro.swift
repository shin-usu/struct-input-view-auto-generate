
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MyMacroMacros", type: "StringifyMacro")

@attached(member, names: named(parameters), named(updateParameters))
public macro DynamicParameters() = #externalMacro(module: "MyMacroMacros", type: "DynamicParametersMacro")
