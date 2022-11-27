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
        generator gen: CodeGenerator,
        type: any SType
    ) throws -> any TypeConverter {
        let repr = type.toTypeRepr(containsModule: false)

        if let customProvider,
           let converter = customProvider(gen, type)
        {
            return converter
        } else if let mapped = typeMap.map(repr: repr) {
            return RawTypeConverter(
                generator: gen, type: type, tsType: mapped
            )
        } else if type.isStandardLibraryType("Optional") {
            return OptionalConverter(gen: gen, type: type)
        } else if type.isStandardLibraryType("Array") {
            return ArrayConverter(gen: gen, type: type)
        } else if type.isStandardLibraryType("Dictionary") {
            return DictionaryConverter(gen: gen, type: type)
        } else if let type = type.asEnum {
            return EnumConverter(gen: gen, type: type)
        } else if let type = type.asStruct {
            return StructConverter(gen: gen, type: type)
        } else if let type = type.asGenericParam {
            return GenericParamConverter(gen: gen, type: type)
        } else if let type = type.asError {
            return ErrorTypeConverter(gen: gen, type: type)
        } else {
            throw MessageError("Unsupported type: \(type)")
        }
    }
}
