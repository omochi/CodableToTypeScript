import XCTest
import CodableToTypeScript
import SwiftTypeReader

final class HelperLibraryTests: XCTestCase {
    func testHelperLibrary() {
        let gen = CodeGenerator(context: Context())
        let code = gen.generateHelperLibrary()

        let actual = code.print()

        assertText(
            text: actual,
            expecteds: ["""
export function identity<T>(json: T): T {
    return json;
}
""", """
export function OptionalField_decode<T, T_JSON>(json: T_JSON | undefined, T_decode: (json: T_JSON) => T): T | undefined {
    if (json === undefined) return undefined;
    return T_decode(json);
}
""", """
export function OptionalField_encode<T, T_JSON>(entity: T | undefined, T_encode: (entity: T) => T_JSON): T_JSON | undefined {
    if (entity === undefined) return undefined;
    return T_encode(entity);
}
""", """
export function Optional_decode<T, T_JSON>(json: T_JSON | null, T_decode: (json: T_JSON) => T): T | null {
    if (json === null) return null;
    return T_decode(json);
}
""", """
export function Optional_encode<T, T_JSON>(entity: T | null, T_encode: (entity: T) => T_JSON): T_JSON | null {
    if (entity === null) return null;
    return T_encode(entity);
}
""", """
export function Array_decode<T, T_JSON>(json: T_JSON[], T_decode: (json: T_JSON) => T): T[] {
    return json.map(T_decode);
}
""", """
export function Array_encode<T, T_JSON>(entity: T[], T_encode: (entity: T) => T_JSON): T_JSON[] {
    return entity.map(T_encode);
}
""", """
export function Dictionary_decode<T, T_JSON>(json: {
    [key: string]: T_JSON;
}, T_decode: (json: T_JSON) => T): {
    [key: string]: T;
} {
    const entity: {
        [key: string]: T;
    } = {};
    for (const k in json) {
        if (json.hasOwnProperty(k)) {
            entity[k] = T_decode(json[k]);
        }
    }
    return entity;
}
""", """
export function Dictionary_encode<T, T_JSON>(entity: {
    [key: string]: T;
}, T_encode: (entity: T) => T_JSON): {
    [key: string]: T_JSON;
} {
    const json: {
        [key: string]: T_JSON;
    } = {};
    for (const k in entity) {
        if (entity.hasOwnProperty(k)) {
            json[k] = T_encode(entity[k]);
        }
    }
    return json;
}
""", """
export type TagOf<Type> = Type extends {
    $tag?: infer TAG;
} ? TAG : never;
""", """
export type TagRecord<Name extends string, Args extends any[] = []> = Args["length"] extends 0 ? {
    $tag?: Name;
} : {
    $tag?: Name & {
        [I in keyof Args]: TagOf<Args[I]>;
    };
};
"""
            ]
        )
    }
}
