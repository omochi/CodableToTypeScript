import XCTest
import CodableToTypeScript
import SwiftTypeReader
import TypeScriptAST

final class GenerateCustomTypeConverterTests: GenerateTestCaseBase {
    /*
     Use TypeMap instead of custom TypeConverter as much as possible
     */
    struct CustomConverter: TypeConverter {
        var generator: CodeGenerator
        var swiftType: any SType

        func name(for target: GenerationTarget) throws -> String {
            switch target {
            case .entity: return "Custom"
            case .json: return try `default`.name(for: .json)
            }
        }

        func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
            return nil
        }

        func decodePresence() throws -> CodecPresence {
            return .required
        }

        func decodeName() throws -> String {
            return "Custom_decode"
        }

        func decodeDecl() throws -> TSFunctionDecl? {
            return nil
        }

        func encodePresence() throws -> CodecPresence {
            return .required
        }

        func encodeName() throws -> String {
            return "Custom_encode"
        }

        func encodeDecl() throws -> TSFunctionDecl? {
            return nil
        }
    }

    func testCustomTypeConverter() throws {
        let typeConverterProvider = TypeConverterProvider { (gen, type) in
            let repr = type.toTypeRepr(containsModule: false)
            if let ident = repr.asIdent,
               let element = ident.elements.last,
               element.name == "Custom"
            {
                return CustomConverter(generator: gen, swiftType: type)
            }
            return nil
        }

        try assertGenerate(
            source: """
struct S {
    var a: Custom
    var b: [Custom]
    var c: [[Custom]]
}
""",
            typeConverterProvider: typeConverterProvider,
            externalReference: ExternalReference(
                symbols: ["Custom", "Custom_JSON", "Custom_decode", "Custom_encode"],
                code: """
                export type Custom = {};
                export type Custom_JSON = string;
                export function Custom_decode(json: Custom_JSON): Custom { throw 0; }
                export function Custom_encode(entity: Custom): Custom_JSON { throw 0; }
                """
            ),
            expecteds: ["""
export type S = {
    a: Custom;
    b: Custom[];
    c: Custom[][];
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: Custom_JSON;
    b: Custom_JSON[];
    c: Custom_JSON[][];
};
""", """
export function S_decode(json: S_JSON): S {
    const a = Custom_decode(json.a);
    const b = Array_decode(json.b, Custom_decode);
    const c = Array_decode(json.c, (json: Custom_JSON[]): Custom[] => {
        return Array_decode(json, Custom_decode);
    });
    return {
        a: a,
        b: b,
        c: c
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    const a = Custom_encode(entity.a);
    const b = Array_encode(entity.b, Custom_encode);
    const c = Array_encode(entity.c, (entity: Custom[]): Custom_JSON[] => {
        return Array_encode(entity, Custom_encode);
    });
    return {
        a: a,
        b: b,
        c: c
    };
}
"""
                   ]
        )
    }}
