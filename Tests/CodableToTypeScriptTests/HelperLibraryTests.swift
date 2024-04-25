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
export function OptionalField_decode<T, T$JSON>(json: T$JSON | undefined, T_decode: (json: T$JSON) => T): T | undefined {
    if (json === undefined) return undefined;
    return T_decode(json);
}
""", """
export function OptionalField_encode<T, T$JSON>(entity: T | undefined, T_encode: (entity: T) => T$JSON): T$JSON | undefined {
    if (entity === undefined) return undefined;
    return T_encode(entity);
}
""", """
export function Optional_decode<T, T$JSON>(json: T$JSON | null, T_decode: (json: T$JSON) => T): T | null {
    if (json === null) return null;
    return T_decode(json);
}
""", """
export function Optional_encode<T, T$JSON>(entity: T | null, T_encode: (entity: T) => T$JSON): T$JSON | null {
    if (entity === null) return null;
    return T_encode(entity);
}
""", """
export function Array_decode<T, T$JSON>(json: T$JSON[], T_decode: (json: T$JSON) => T): T[] {
    return json.map(T_decode);
}
""", """
export function Array_encode<T, T$JSON>(entity: T[], T_encode: (entity: T) => T$JSON): T$JSON[] {
    return entity.map(T_encode);
}
""", """
export function Set_decode<T, T$JSON>(json: T$JSON[], T_decode: (json: T$JSON) => T): Set<T> {
    return new Set(json.map(T_decode));
}
""", """
export function Set_encode<T, T$JSON>(entity: Set<T>, T_encode: (entity: T) => T$JSON): T$JSON[] {
    return [... entity].map(T_encode);
}
""", """
export function Dictionary_decode<T, T$JSON>(json: {
    [key: string]: T$JSON;
}, T_decode: (json: T$JSON) => T): Map<string, T> {
    const entity = new Map<string, T>();
    for (const k in json) {
        if (json.hasOwnProperty(k)) {
            entity.set(k, T_decode(json[k]));
        }
    }
    return entity;
}
""", """
export function Dictionary_encode<T, T$JSON>(entity: Map<string, T>, T_encode: (entity: T) => T$JSON): {
    [key: string]: T$JSON;
} {
    const json: {
        [key: string]: T$JSON;
    } = {};
    for (const k in entity.keys()) {
        json[k] = T_encode(entity.get(k) !!);
    }
    return json;
}
""", """
export type TagOf<Type> = [Type] extends [TagRecord<infer TAG>]
    ? TAG
    : null extends Type
        ? "Optional" & [TagOf<Exclude<Type, null>>]
        : Type extends (infer E)[]
            ? "Array" & [TagOf<E>]
            : Type extends Map<string, infer V>
                ? "Dictionary" & [TagOf<V>]
                : never
;
""", """
export type TagRecord<Name extends string, Args extends any[] = []> = Args["length"] extends 0
    ? {
        $tag?: Name;
    }
    : {
        $tag?: Name & {
            [I in keyof Args]: TagOf<Args[I]>;
        };
    }
;
"""
            ]
        )
    }
}
