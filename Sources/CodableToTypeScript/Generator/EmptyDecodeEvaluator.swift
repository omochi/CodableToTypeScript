import SwiftTypeReader

final class EmptyDecodeEvaluator {
    init(typeMap: TypeMap) {
        self.typeMap = typeMap
    }

    var typeMap: TypeMap
    var result: [TypeKey: Bool] = [:]

    func evaluate(type: SType) throws -> Bool {
        return try visit(type: type, visiteds: [])
    }

    private func visit(
        type: SType, visiteds: Set<TypeKey>
    ) throws -> Bool {
        let key = try TypeKey(type: type)
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
        type: SType, visiteds: Set<TypeKey>
    ) throws -> Bool {
        if let _ = typeMap.map(specifier: type.asSpecifier()) {
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

        guard let type = type.regular else {
            throw MessageError("Unresolved type (\(type.asSpecifier())) can't be evaluated")
        }

        switch type {
        case .enum(let type):
            if type.caseElements.isEmpty { return true }
            if SType.enum(type).hasStringRawValue() { return true }
            return false
        case .struct(let type):
            for field in type.storedProperties {
                if try !visit(
                    type: field.type(),
                    visiteds: visiteds
                ) {
                    return false
                }
            }
            return true
        case .genericParameter:
            return false
        case .protocol:
            return true
        }

    }
}
