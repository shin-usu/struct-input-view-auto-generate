//import SwiftUI
//
//protocol DynamicKeyPathProvider {
//    static func keyPathForLabel<Value>(_ label: String) -> WritableKeyPath<Self, Value>?
//}
//
//protocol KeyPathListable {
//    var allKeyPaths: [String: PartialKeyPath<Self>] { get }
//}
//
//extension KeyPathListable {
//
//    private subscript(checkedMirrorDescendant key: String) -> Any {
//        return Mirror(reflecting: self).descendant(key)!
//    }
//
//    var allKeyPaths: [String: PartialKeyPath<Self>] {
//        var membersTokeyPaths = [String: PartialKeyPath<Self>]()
//        let mirror = Mirror(reflecting: self)
//        for case (let key?, _) in mirror.children {
//            membersTokeyPaths[key] = \Self.[checkedMirrorDescendant: key] as PartialKeyPath
//        }
//        return membersTokeyPaths
//    }
//
//}
//
//// サンプルのリクエスト型
//struct HogeRequest: Identifiable, DynamicKeyPathProvider, KeyPathListable {
//    static func keyPathForLabel<Value>(_ label: String) -> WritableKeyPath<HogeRequest, Value>? {
//            switch label {
//            case "command": return \HogeRequest.command as? WritableKeyPath<HogeRequest, Value>
//            case "duration": return \HogeRequest.duration as? WritableKeyPath<HogeRequest, Value>
//            case "isActive": return \HogeRequest.isActive as? WritableKeyPath<HogeRequest, Value>
//            case "options": return \HogeRequest.options as? WritableKeyPath<HogeRequest, Value>
//            case "subRequest": return \HogeRequest.subRequest as? WritableKeyPath<HogeRequest, Value>
//            default: return nil
//            }
//        }
//    
//    var id = UUID() // 配列の識別子
//    var command: String
//    var duration: Int
//    var isActive: Bool?
//    var options: [String]
//    var subRequest: SubRequest
//}
//
//struct SubRequest: Identifiable, DynamicKeyPathProvider, KeyPathListable {
//    var id = UUID()
//    var detail: String
//    var count: Int
//    var tags: [String]
//
//    static func keyPathForLabel<Value>(_ label: String) -> WritableKeyPath<SubRequest, Value>? {
//        switch label {
//        case "detail": return \SubRequest.detail as? WritableKeyPath<SubRequest, Value>
//        case "count": return \SubRequest.count as? WritableKeyPath<SubRequest, Value>
//        case "tags": return \SubRequest.tags as? WritableKeyPath<SubRequest, Value>
//        default: return nil
//        }
//    }
//}
//
//struct DynamicFieldsView<T: KeyPathListable>: View {
//    @Binding var instance: T
//
//    var body: some View {
//        let mirror = Mirror(reflecting: instance)
//        VStack {
//            ForEach(Array(mirror.children.enumerated()), id: \.offset) { index, child in
//                if let label = child.label {
//                    DynamicFieldView(
//                        label: label,
//                        value: Binding(
//                            get: {
//                                // 現在のプロパティの値を取得
//                                child.value
//                            },
//                            set: { newValue in
//                                // プロパティの値を更新
//                                if var mutableInstance = instance as? AnyObject {
//                                    mutableInstance.setValue(newValue, forKey: label)
//                                } else {
//                                    print("Unable to set value dynamically for \(label)")
//                                }
//                            }
//                        )
//                    )
//                    // WritableKeyPathを取得
////                    if let keyPath = instance.allKeyPaths[label] {
////                        // 動的にフィールドを生成
////                        DynamicFieldView(
////                            label: label,
////                            value: Binding(
////                                get: { instance[keyPath: keyPath] },
////                                set: { newValue in
////                                    let new = keyPath as! WritableKeyPath<T, Any>
////                                    instance[keyPath: new] = newValue
////                                }
////                            )
////                        )
////                    } else {
////                        Text("Unsupported property: \(label)")
////                            .foregroundColor(.red)
////                    }
//                }
//            }
//        }
//    }
//}
//
//struct DynamicFieldView<Value>: View {
//    let label: String
//    @Binding var value: Value
//
//    var body: some View {
//        HStack {
//            Text(label)
//            Spacer()
//            if let stringValue = value as? String {
//                TextField("Enter \(label)", text: Binding(
//                    get: { stringValue },
//                    set: { newValue in
//                        if let newValue = newValue as? Value {
//                            self.value = newValue
//                        }
//                    }
//                ))
//            } else if let intValue = value as? Int {
//                TextField("Enter \(label)", value: Binding(
//                    get: { intValue },
//                    set: { newValue in
//                        if let newValue = newValue as? Value {
//                            self.value = newValue
//                        }
//                    }
//                ), formatter: NumberFormatter())
//            } else if let boolValue = value as? Bool {
//                Toggle(label, isOn: Binding(
//                    get: { boolValue },
//                    set: { newValue in
//                        if let newValue = newValue as? Value {
//                            self.value = newValue
//                        }
//                    }
//                ))
//            } else {
//                Text("Unsupported type")
//                    .foregroundColor(.gray)
//            }
//        }
//        .padding()
//    }
//}
//
////struct ContentView: View {
////    @State var request = HogeRequest(
////        command: "Start",
////        duration: 30,
////        isActive: true,
////        options: ["Option1", "Option2"],
////        subRequest: SubRequest(detail: "Detail", count: 5, tags: ["Tag1", "Tag2"])
////    )
////
////    var body: some View {
////        DynamicFieldsView(instance: $request)
////    }
////}
////
////#Preview {
////    ContentView()
////}
