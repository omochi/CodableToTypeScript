import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class CodeGenerator {
    internal final class RequestToken: HashableFromIdentity {
        unowned let generator: CodeGenerator
        init(generator: CodeGenerator) {
            self.generator = generator
        }
    }

    internal var requestToken: RequestToken!
    public let context: SwiftTypeReader.Context
    private let typeConverterProvider: TypeConverterProvider

    public init(
        context: SwiftTypeReader.Context,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider()
    ) {
        self.context = context
        self.typeConverterProvider = typeConverterProvider
        self.requestToken = RequestToken(generator: self)
    }

    public func convert(source: SourceFile) throws -> TSSourceFile {
        let tsSource = TSSourceFile([])

        try withErrorCollector { collect in
            for type in source.types {
                if let typeConverter = try? converter(
                    for: type.declaredInterfaceType
                ) {
                    collect {
                        tsSource.elements += try typeConverter.decls()
                    }
                }
            }
        }

        return tsSource
    }

    public func converter(for type: any SType) throws -> any TypeConverter {
        return try context.evaluator(
            ConverterRequest(token: requestToken, type: type)
        )
    }

    private func implConverter(for type: any SType) throws -> any TypeConverter {
        return try typeConverterProvider.provide(generator: self, type: type)
    }

    internal struct ConverterRequest: Request {
        var token: RequestToken
        @AnyTypeStorage var type: any SType
        private var generator: CodeGenerator { token.generator }

        func evaluate(on evaluator: RequestEvaluator) throws -> any TypeConverter {
            let impl = try generator.implConverter(for: type)
            return GeneratorProxyConverter(generator: generator, swiftType: type, impl: impl)
        }
    }

    internal struct DecodePresenceRequest: Request {
        var token: RequestToken
        @AnyTypeStorage var type: any SType

        func evaluate(on evaluator: RequestEvaluator) throws -> CodecPresence {
            do {
                let converter = try token.generator.implConverter(for: type)
                return try converter.decodePresence()
            } catch {
                switch error {
                case is CycleRequestError: return .required
                default: throw error
                }
            }
        }
    }

    internal struct EncodePresenceRequest: Request {
        var token: RequestToken
        @AnyTypeStorage var type: any SType

        func evaluate(on evaluator: RequestEvaluator) throws -> CodecPresence {
            do {
                let converter = try token.generator.implConverter(for: type)
                return try converter.encodePresence()
            } catch {
                switch error {
                case is CycleRequestError: return .required
                default: throw error
                }
            }
        }
    }

    func helperLibrary() -> HelperLibraryGenerator {
        return HelperLibraryGenerator(generator: self)
    }

    public func generateHelperLibrary() -> TSSourceFile {
        return helperLibrary().generate()
    }

    public func callDecode(
        callee: any TSExpr,
        genericArgs: [any SType],
        json: any TSExpr
    ) throws -> any TSExpr {
        let genericArgs = try genericArgs.map {
            try converter(for: $0)
        }

        var args: [any TSExpr] = [json]

        args += try genericArgs.map { (arg) in
            return try arg.boundDecode()
        }

        let callGenericArgs: [any TSType] = try genericArgs.flatMap { (arg) in
            return [
                try arg.type(for: .entity),
                try arg.type(for: .json)
            ]
        }

        return TSCallExpr(
            callee: callee,
            genericArgs: callGenericArgs,
            args: args
        )
    }

    public func callEncode(
        callee: any TSExpr,
        genericArgs: [any SType],
        entity: any TSExpr
    ) throws -> any TSExpr {
        let genericArgs = try genericArgs.map {
            try converter(for: $0)
        }

        var args: [any TSExpr] = [entity]

        args += try genericArgs.map { (arg) in
            return try arg.boundEncode()
        }

        let callGenericArgs: [any TSType] = try genericArgs.flatMap { (arg) in
            return [
                try arg.type(for: .entity),
                try arg.type(for: .json)
            ]
        }

        return TSCallExpr(
            callee: callee,
            genericArgs: callGenericArgs,
            args: args
        )
    }

    public func tagRecord(
        name: String,
        genericArgs: [any TSType]
    ) throws -> TSIdentType {
        var recordArgs: [any TSType] = [
            TSStringLiteralType(name)
        ]

        if !genericArgs.isEmpty {
            recordArgs.append(TSTupleType(genericArgs))
        }

        return TSIdentType(
            "TagRecord",
            genericArgs: recordArgs
        )
    }
}
