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
        let repr = type.toTypeRepr(containsModule: false)

        if let customProvider,
           let converter = customProvider(generator, type)
        {
            return converter
        } else if let mapped = typeMap.map(repr: repr) {
            return StaticConverter(
                generator: generator, type: type, tsName: mapped
            )
        } else if type.isStandardLibraryType("Optional") {
            return OptionalConverter(generator: generator, type: type)
        } else if type.isStandardLibraryType("Array") {
            return ArrayConverter(generator: generator, type: type)
        } else if type.isStandardLibraryType("Dictionary") {
            return DictionaryConverter(generator: generator, type: type)
        } else if let type = type.asEnum {
            return EnumConverter(generator: generator, enum: type)
        } else if let type = type.asStruct {
            return StructConverter(generator: generator, struct: type)
        } else if let type = type.asGenericParam {
            return GenericParamConverter(generator: generator, param: type)
        } else if let type = type.asError {
            return ErrorTypeConverter(generator: generator, type: type)
        } else {
            throw MessageError("Unsupported type: \(type)")
        }
    }
}