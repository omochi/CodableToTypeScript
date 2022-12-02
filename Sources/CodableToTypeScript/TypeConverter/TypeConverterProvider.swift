import SwiftTypeReader

public struct TypeConverterProvider {
    public typealias CustomProvider = (CodeGenerator, any SType) -> (any TypeConverter)?

    public init(
        typeMap: TypeMap = .default,
        customProvider: CustomProvider? = nil
    ) {
        self.typeMap = typeMap
        self.customProvider = customProvider
    }

    public var typeMap: TypeMap
    public var customProvider: CustomProvider?

    public func provide(
        generator: CodeGenerator,
        type: any SType
    ) throws -> any TypeConverter {
        if let customProvider,
           let converter = customProvider(generator, type)
        {
            return converter
        } else if let entry = typeMap.map(type: type) {
            return TypeMapConverter(generator: generator, type: type, entry: entry)
        } else if type.isStandardLibraryType("Optional") {
            return OptionalConverter(generator: generator, swiftType: type)
        } else if type.isStandardLibraryType("Array") {
            return ArrayConverter(generator: generator, swiftType: type)
        } else if type.isStandardLibraryType("Dictionary") {
            return DictionaryConverter(generator: generator, swiftType: type)
        } else if let type = type.asEnum {
            return EnumConverter(generator: generator, enum: type)
        } else if let type = type.asStruct {
            if let raw = type.decl.isRawRepresentable() {
                return RawRepresentableConverter(
                    generator: generator,
                    swiftType: type,
                    rawValueType: try generator.converter(for: raw)
                )
            }

            return StructConverter(generator: generator, struct: type)
        } else if let type = type.asGenericParam {
            return GenericParamConverter(generator: generator, param: type)
        } else if let type = type.asError {
            return ErrorTypeConverter(generator: generator, swiftType: type)
        } else {
            throw MessageError("Unsupported type: \(type)")
        }
    }
}
