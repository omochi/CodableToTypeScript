import SwiftTypeReader

final class EmptyDecodeEvaluator: HashableFromIdentity {
    struct Request: SwiftTypeReader.Request {
        var evaluator: EmptyDecodeEvaluator
        @AnyTypeStorage var type: any SType

        func evaluate(on evaluator: RequestEvaluator) throws -> Bool {
            return try self.evaluator.evaluateImpl(type: type)
        }
    }

    init(
        evaluator: RequestEvaluator,
        typeMap: TypeMap
    ) {
        self.evaluator = evaluator
        self.typeMap = typeMap
    }

    let evaluator: RequestEvaluator
    let typeMap: TypeMap

    func evaluate(_ type: any SType) throws -> Bool {
        do {
            return try evaluator(
                Request(evaluator: self, type: type)
            )
        } catch {
            switch error {
            case is CycleRequestError:
                // cycle type needs decoder
                return false
            default:
                throw error
            }
        }
    }

    private func evaluateImpl(type: any SType) throws -> Bool {
        let repr = type.toTypeRepr(containsModule: false)
        if let _ = typeMap.map(repr: repr) {
            /*
             mapped type doesn't have decoder
             */
            return true
        }

        if let (wrapped, _) = type.unwrapOptional(limit: nil) {
            return try evaluate(wrapped)
        }
        if let (_, element) = type.asArray() {
            return try evaluate(element)
        }
        if let (_, value) = type.asDictionary() {
            return try evaluate(value)
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
                if try !evaluate(field.interfaceType) {
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
