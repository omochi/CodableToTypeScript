import Foundation

public struct TSRecordType: PrettyPrintable {
    public struct Field {
        public init(name: String, type: TSType, isOptional: Bool = false) {
            self.name = name
            self.type = type
            self.isOptional = isOptional
        }

        public var name: String
        public var type: TSType
        public var isOptional: Bool
    }

    public init(_ fields: [TSRecordType.Field]) {
        self.fields = fields
    }

    public var fields: [Field]

    public func print(printer p: PrettyPrinter) {
        if fields.isEmpty {
            p.write("{}")
            return
        }

        p.writeLine("{")
        p.nest {
            for field in fields {
                p.write(field.name)
                if field.isOptional {
                    p.write("?: ")
                } else {
                    p.write(": ")
                }
                p.write(field.type)
                p.writeLine(";")
            }
        }
        p.write("}")
    }
}
