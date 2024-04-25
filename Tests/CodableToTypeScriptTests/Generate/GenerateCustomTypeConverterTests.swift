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

        func hasDecode() throws -> Bool {
            return true
        }

        func decodeName() throws -> String {
            return "Custom_decode"
        }

        func decodeDecl() throws -> TSFunctionDecl? {
            return nil
        }

        func hasEncode() throws -> Bool {
            return true
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
                symbols: ["Custom", "Custom$JSON", "Custom_decode", "Custom_encode"],
                code: """
                export type Custom = {};
                export type Custom$JSON = string;
                export function Custom_decode(json: Custom$JSON): Custom { throw 0; }
                export function Custom_encode(entity: Custom): Custom$JSON { throw 0; }
                """
            ),
            expecteds: ["""
export type S = {
    a: Custom;
    b: Custom[];
    c: Custom[][];
} & TagRecord<"S">;
""", """
export type S$JSON = {
    a: Custom$JSON;
    b: Custom$JSON[];
    c: Custom$JSON[][];
};
""", """
export function S_decode(json: S$JSON): S {
    const a = Custom_decode(json.a);
    const b = Array_decode<Custom, Custom$JSON>(json.b, Custom_decode);
    const c = Array_decode<Custom[], Custom$JSON[]>(json.c, (json: Custom$JSON[]): Custom[] => {
        return Array_decode<Custom, Custom$JSON>(json, Custom_decode);
    });
    return {
        a: a,
        b: b,
        c: c
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    const a = Custom_encode(entity.a);
    const b = Array_encode<Custom, Custom$JSON>(entity.b, Custom_encode);
    const c = Array_encode<Custom[], Custom$JSON[]>(entity.c, (entity: Custom[]): Custom$JSON[] => {
        return Array_encode<Custom, Custom$JSON>(entity, Custom_encode);
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
