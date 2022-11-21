import SwiftTypeReader

final class EmptyDecodeEvaluator {
    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    var typeMap: TypeMap
    var result: [TypeKey: Bool] = [:]

    func evaluate(type: any SType) throws -> Bool {
        return try visit(type: type, visiteds: [])
    }

    private func visit(
        type: any SType, visiteds: Set<TypeKey>
    ) throws -> Bool {
        let key = TypeKey(type: type)
        if let cache = result[key] {
            return cache
        }

        if visiteds.contains(key) {
            return false
        }

        let result = try _visit(
            type: type,
            visiteds: visiteds.union([key])
        )
        self.result[key] = result
        return result
    }

    private func _visit(
        type: any SType, visiteds: Set<TypeKey>
    ) throws -> Bool {
        let repr = type.toTypeRepr(containsModule: false)
        if let _ = typeMap.map(repr: repr) {
            /*
             mapped type doesn't have decoder
             */
            return true
        }

        if let (wrapped, _) = type.unwrapOptional(limit: nil) {
            return try visit(type: wrapped, visiteds: visiteds)
        }
        if let (_, element) = type.asArray() {
            return try visit(type: element, visiteds: visiteds)
        }
        if let (_, value) = type.asDictionary() {
            return try visit(type: value, visiteds: visiteds)
        }

        if type is ErrorType {
            throw MessageError("Unresolved type (\(repr)) can't be evaluated")
        }

        switch type {
        case let type as EnumType:
            if type.decl.caseElements.isEmpty { return true }
            if type.hasStringRawValue() { return true }
            return false
        case let type as StructType:
            for field in type.decl.storedProperties {
                if try !visit(
                    type: field.interfaceType,
                    visiteds: visiteds
                ) {
                    return false
                }
            }
            return true
        case is GenericParamType:
            return false
        default:
            return true
        }
    }
}
