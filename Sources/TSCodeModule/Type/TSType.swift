public indirect enum TSType: PrettyPrintable {
    case array(TSArrayType)
    case dictionary(TSDictionaryType)
    case function(TSFunctionType)
    case named(TSNamedType)
    case nested(TSNestedType)
    case record(TSRecordType)
    case stringLiteral(TSStringLiteralType)
    case union(TSUnionType)

    public func print(printer: PrettyPrinter) {
        switch self {
        case .array(let t): t.print(printer: printer)
        case .dictionary(let t): t.print(printer: printer)
        case .function(let t): t.print(printer: printer)
        case .named(let t): t.print(printer: printer)
        case .nested(let t): t.print(printer: printer)
        case .record(let t): t.print(printer: printer)
        case .stringLiteral(let t): t.print(printer: printer)
        case .union(let t): t.print(printer: printer)
        }
    }

    public var named: TSNamedType? {
        switch self {
        case .named(let x): return x
        default: return nil
        }
    }

    public static func array(_ element: TSType) -> TSType {
        .array(TSArrayType(element))
    }

    public static func dictionary(_ element: TSType) -> TSType {
        .dictionary(TSDictionaryType(element))
    }

    public static func function(parameters: [TSFunctionParameter], returnType: TSType) -> TSType {
        .function(TSFunctionType(parameters: parameters, returnType: returnType))
    }

    public static func named(_ name: String, genericArguments: [TSGenericArgument] = []) -> TSType {
        .named(TSNamedType(name, genericArguments: genericArguments))
    }

    public static func nested(namespace: String, type: TSType) -> TSType {
        .nested(TSNestedType(namespace: namespace, type: type))
    }

    public static func record(_ fields: [TSRecordType.Field]) -> TSType {
        .record(TSRecordType(fields))
    }

    public static func stringLiteral(_ value: String) -> TSType {
        .stringLiteral(TSStringLiteralType(value))
    }

    public static func union(_ items: [TSType]) -> TSType {
        .union(TSUnionType(items))
    }

    public static func union(_ items: TSType...) -> TSType {
        union(items)
    }

    public static func orNull(_ type: TSType) -> TSType {
        .union([type, .named(.null)])
    }

    public static func orUndefined(_ type: TSType) -> TSType {
        .union([type, .named(.undefined)])
    }
}

extension [TSType] {
    public func print(printer: PrettyPrinter) {
        if isEmpty { return }

        let isBig = count > printer.smallNumber

        if isBig {
            printer.writeLine("")
            printer.push()
        } else {
            if !printer.isStartOfLine {
                printer.write(" ")
            }
        }

        for (index, type) in enumerated() {
            if index > 0 {
                if isBig {
                    printer.writeLine(",")
                } else {
                    printer.write(", ")
                }
            }

            type.print(printer: printer)
        }

        if isBig {
            printer.writeLine("")
            printer.pop()
        }
    }
}
