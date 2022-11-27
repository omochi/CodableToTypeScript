import Foundation
import SwiftTypeReader
import TypeScriptAST

public final class CodeGenerator {
    internal final class RequestToken: HashableFromIdentity {
        unowned let gen: CodeGenerator
        init(gen: CodeGenerator) {
            self.gen = gen
        }
    }

    internal var requestToken: RequestToken!
    public let context: Context
    private let typeConverterProvider: TypeConverterProvider

    public init(
        context: Context,
        typeConverterProvider: TypeConverterProvider = TypeConverterProvider()
    ) {
        self.context = context
        self.typeConverterProvider = typeConverterProvider
        self.requestToken = RequestToken(gen: self)
    }

    public func converter(for type: any SType) throws -> any TypeConverter {
        return try context.evaluator(
            ConverterRequest(token: requestToken, type: type)
        )
    }

    public func converter(for decl: any TypeDecl) throws -> any TypeConverter {
        return try converter(for: decl.declaredInterfaceType)
    }

    private func implConverter(for type: any SType) throws -> any TypeConverter {
        return try typeConverterProvider.provide(generator: self, type: type)
    }

    internal struct ConverterRequest: Request {
        var token: RequestToken
        @AnyTypeStorage var type: any SType
        private var gen: CodeGenerator { token.gen }

        func evaluate(on evaluator: RequestEvaluator) throws -> any TypeConverter {
            let impl = try gen.implConverter(for: type)
            return GeneratorProxyConverter(generator: gen, type: type, impl: impl)
        }
    }

    internal struct HasJSONTypeRequest: Request {
        var token: RequestToken
        @AnyTypeStorage var type: any SType

        func evaluate(on evaluator: RequestEvaluator) throws -> Bool {
            do {
                let converter = try token.gen.implConverter(for: type)
                return try converter.hasJSONType()
            } catch {
                switch error {
                case is CycleRequestError: return true
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
        var args: [any TSExpr] = [json]

        for arg in genericArgs {
            let decode = try converter(for: arg).boundDecode()
            args.append(decode)
        }

        return TSCallExpr(callee: callee, args: args)
    }
}
