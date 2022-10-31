import XCTest
import CodableToTypeScript

final class GenerateGenericTests: GenerateTestCaseBase {
    func testSimple() throws {
        try assertGenerate(
            source: """
struct S<T> {
    var a: T
}
""",
            expecteds: ["""
export type S<T> = {
    a: T;
};
""", """
export type S_JSON<T_JSON> = {
    a: T_JSON;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    return {
        a: T_decode(json.a)
    };
}
"""]
        )
    }

    func testParameterTranspile() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}

struct S {
    var a: K<Int>
}
""",
            expecteds: ["""
export type S = {
    a: K<number>;
};
""", """
export type S_JSON = {
    a: K_JSON<number>;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: K_decode(json.a, identity)
    };
}
"""
            ]
        )
    }

    func testTwoParameters() throws {
        try assertGenerate(
            source: """
struct S<A, B> {
    var a: A
    var b: B
}
""",
            expecteds: ["""
export type S<A, B> = {
    a: A;
    b: B;
};
""", """
export type S_JSON<A_JSON, B_JSON> = {
    a: A_JSON;
    b: B_JSON;
};
""", """
export function S_decode<
    A,
    B,
    A_JSON,
    B_JSON
>(json: S_JSON<A_JSON, B_JSON>, A_decode: (json: A_JSON) => A, B_decode: (json: B_JSON) => B): S<A, B> {
    return {
        a: A_decode(json.a),
        b: B_decode(json.b)
    };
}
"""]
        )
    }

    func testThreeParameters() throws {
        try assertGenerate(
            source: """
struct S<A, B, C> {
    var a: A
    var b: B
    var c: C
}
""",
            expecteds: ["""
export type S<A, B, C> = {
    a: A;
    b: B;
    c: C;
};
""", """
export type S_JSON<A_JSON, B_JSON, C_JSON> = {
    a: A_JSON;
    b: B_JSON;
    c: C_JSON;
};
""", """
export function S_decode<
    A,
    B,
    C,
    A_JSON,
    B_JSON,
    C_JSON
>(
    json: S_JSON<A_JSON, B_JSON, C_JSON>,
    A_decode: (json: A_JSON) => A,
    B_decode: (json: B_JSON) => B,
    C_decode: (json: C_JSON) => C
): S<A, B, C> {
    return {
        a: A_decode(json.a),
        b: B_decode(json.b),
        c: C_decode(json.c)
    };
}
"""]
        )
    }

    func testForwardGenericParameter() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}
struct L<U> {
    var a: U
}
struct X<T> {}

struct S<T> {
    var a: K<T>
    var b: L<T>
    var c: X<T>
}
""",
            expecteds: ["""
export type S<T> = {
    a: K<T>;
    b: L<T>;
    c: X<T>;
};
""", """
export type S_JSON<T_JSON> = {
    a: K_JSON<T_JSON>;
    b: L_JSON<T_JSON>;
    c: X<T_JSON>;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    return {
        a: K_decode(json.a, T_decode),
        b: L_decode(json.b, T_decode),
        c: json.c
    };
}
"""]
        )
    }

    func testForwardTwoGenericParameter() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}

struct L<A, B> {
    var a: A
    var b: B
}

struct S<T, U> {
    var a: K<T>
    var b: K<U>
    var c: L<T, T>
    var d: L<T, U>
}
""",
            expecteds: ["""
export type S<T, U> = {
    a: K<T>;
    b: K<U>;
    c: L<T, T>;
    d: L<T, U>;
};
""", """
export type S_JSON<T_JSON, U_JSON> = {
    a: K_JSON<T_JSON>;
    b: K_JSON<U_JSON>;
    c: L_JSON<T_JSON, T_JSON>;
    d: L_JSON<T_JSON, U_JSON>;
};
""", """
export function S_decode<
    T,
    U,
    T_JSON,
    U_JSON
>(json: S_JSON<T_JSON, U_JSON>, T_decode: (json: T_JSON) => T, U_decode: (json: U_JSON) => U): S<T, U> {
    return {
        a: K_decode(json.a, T_decode),
        b: K_decode(json.b, U_decode),
        c: L_decode(json.c, T_decode, T_decode),
        d: L_decode(json.d, T_decode, U_decode)
    };
}
"""
            ]
        )
    }

    func testApplyFixedType() throws {
        try assertGenerate(
            source: """
enum E { case a }
struct K<T> {
    var a: T
}
struct A {
    var a: Int
}
struct B {
    var a: E
}
struct C {}

struct S {
    var i: K<Int>
    var a: K<A>
    var b: K<B>
    var c: K<C>
}
""",
            expecteds: ["""
export type S = {
    i: K<number>;
    a: K<A>;
    b: K<B>;
    c: K<C>;
};
""", """
export type S_JSON = {
    i: K_JSON<number>;
    a: K_JSON<A>;
    b: K_JSON<B_JSON>;
    c: K_JSON<C>;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        i: K_decode(json.i, identity),
        a: K_decode(json.a, identity),
        b: K_decode(json.b, B_decode),
        c: K_decode(json.c, identity)
    };
}
"""
            ]
        )
    }

    func testApplyComposedType() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct K<T> {
    var a: T
}

struct S {
    var a: K<Int?>
    var b: K<[Int]>
    var c: K<E?>
    var d: K<[E]>
}
""",
        expecteds: ["""
export type S = {
    a: K<number | null>;
    b: K<number[]>;
    c: K<E | null>;
    d: K<E[]>;
};
""", """
export type S_JSON = {
    a: K_JSON<number | null>;
    b: K_JSON<number[]>;
    c: K_JSON<E_JSON | null>;
    d: K_JSON<E_JSON[]>;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: K_decode(json.a, identity),
        b: K_decode(json.b, identity),
        c: K_decode(json.c, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        }),
        d: K_decode(json.d, (json: E_JSON[]): E[] => {
            return Array_decode(json, E_decode);
        })
    };
}
"""
        ])
    }

    func testApplyGenericComposedType() throws {
        try assertGenerate(
            source: """
struct K<T> {
    var a: T
}

struct S<T> {
    var a: K<T?>
    var b: K<[T]>
}
""",
            expecteds: ["""
export type S<T> = {
    a: K<T | null>;
    b: K<T[]>;
};
""", """
export type S_JSON<T_JSON> = {
    a: K_JSON<T_JSON | null>;
    b: K_JSON<T_JSON[]>;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    return {
        a: K_decode(json.a, (json: T_JSON | null): T | null => {
            return Optional_decode(json, T_decode);
        }),
        b: K_decode(json.b, (json: T_JSON[]): T[] => {
            return Array_decode(json, T_decode);
        })
    };
}
"""
            ])
    }

    func testGenericEnum() throws {
        try assertGenerate(
            source: """
enum E<T> {
    case a(T)
}
""",
            expecteds: ["""
export type E<T> = {
    kind: "a";
    a: {
        _0: T;
    };
};
""","""
export type E_JSON<T_JSON> = {
    a: {
        _0: T_JSON;
    };
};
""","""
export function E_decode<T, T_JSON>(json: E_JSON<T_JSON>, T_decode: (json: T_JSON) => T): E<T> {
    if ("a" in json) {
        const j = json.a;
        return {
            kind: "a",
            a: {
                _0: T_decode(j._0)
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}
"""

            ]
        )
    }

    func testNestedGenericParameter() throws {
        try assertGenerate(
            source: """
struct X<T> {
    var a: T
    var b: String
}

struct Y<T> {
    var x: [X<T>]
}
""")
    }

}
