import Foundation

public struct TSRecordType: PrettyPrintable {
    public struct Field: PrettyPrintable {
        public init(name: String, type: TSType, isOptional: Bool = false) {
            self.name = name
            self.type = type
            self.isOptional = isOptional
        }

        public var name: String
        public var type: TSType
        public var isOptional: Bool

        public func print(printer: PrettyPrinter) {
            printer.write(name)
            if isOptional {
                printer.write("?: ")
            } else {
                printer.write(": ")
            }
            printer.write(type)
        }
    }

    public init(_ fields: [Field]) {
        self.fields = fields
    }

    public var fields: [Field]

    public func print(printer: PrettyPrinter) {
        if fields.isEmpty {
            printer.write("{}")
            return
        }

        printer.writeLine("{")
        printer.nest {
            for field in fields {
                field.print(printer: printer)
                printer.writeLine(";")
            }
        }
        printer.write("}")
    }
}

