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
} & TagRecord<"S", [T]>;
""", """
export type S_JSON<T_JSON> = {
    a: T_JSON;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    const a = T_decode(json.a);
    return {
        a: a
    };
}
"""]
        )
    }

    func testParamIdentity() throws {
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
} & TagRecord<"S">;
"""
            ],
            unexpecteds: ["""
export type S_JSON
""", """
export function S_decode
""", """
export function S_encode
"""
            ]
        )
    }

    func testParamDecode() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct K<T> {
    var a: T
}

struct S {
    var a: K<E>
}
""",
            expecteds: ["""
export type S = {
    a: K<E>;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: K_JSON<E_JSON>;
};
""", """
export function S_decode(json: S_JSON): S {
    const a = K_decode<E, E_JSON>(json.a, E_decode);
    return {
        a: a
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
} & TagRecord<"S", [A, B]>;
""", """
export type S_JSON<A_JSON, B_JSON> = {
    a: A_JSON;
    b: B_JSON;
};
""", """
export function S_decode<
    A,
    A_JSON,
    B,
    B_JSON
>(json: S_JSON<A_JSON, B_JSON>, A_decode: (json: A_JSON) => A, B_decode: (json: B_JSON) => B): S<A, B> {
    const a = A_decode(json.a);
    const b = B_decode(json.b);
    return {
        a: a,
        b: b
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
} & TagRecord<"S", [A, B, C]>;
""", """
export type S_JSON<A_JSON, B_JSON, C_JSON> = {
    a: A_JSON;
    b: B_JSON;
    c: C_JSON;
};
""", """
export function S_decode<
    A,
    A_JSON,
    B,
    B_JSON,
    C,
    C_JSON
>(
    json: S_JSON<A_JSON, B_JSON, C_JSON>,
    A_decode: (json: A_JSON) => A,
    B_decode: (json: B_JSON) => B,
    C_decode: (json: C_JSON) => C
): S<A, B, C> {
    const a = A_decode(json.a);
    const b = B_decode(json.b);
    const c = C_decode(json.c);
    return {
        a: a,
        b: b,
        c: c
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
} & TagRecord<"S", [T]>;
""", """
export type S_JSON<T_JSON> = {
    a: K_JSON<T_JSON>;
    b: L_JSON<T_JSON>;
    c: X<T_JSON>;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    const a = K_decode<T, T_JSON>(json.a, T_decode);
    const b = L_decode<T, T_JSON>(json.b, T_decode);
    const c = json.c as X<T>;
    return {
        a: a,
        b: b,
        c: c
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
} & TagRecord<"S", [T, U]>;
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
    T_JSON,
    U,
    U_JSON
>(json: S_JSON<T_JSON, U_JSON>, T_decode: (json: T_JSON) => T, U_decode: (json: U_JSON) => U): S<T, U> {
    const a = K_decode<T, T_JSON>(json.a, T_decode);
    const b = K_decode<U, U_JSON>(json.b, U_decode);
    const c = L_decode<
        T,
        T_JSON,
        T,
        T_JSON
    >(json.c, T_decode, T_decode);
    const d = L_decode<
        T,
        T_JSON,
        U,
        U_JSON
    >(json.d, T_decode, U_decode);
    return {
        a: a,
        b: b,
        c: c,
        d: d
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
} & TagRecord<"S">;
""", """
export type S_JSON = {
    i: K<number>;
    a: K<A>;
    b: K_JSON<B_JSON>;
    c: K<C>;
};
""", """
export function S_decode(json: S_JSON): S {
    const i = json.i as K<number>;
    const a = json.a as K<A>;
    const b = K_decode<B, B_JSON>(json.b, B_decode);
    const c = json.c as K<C>;
    return {
        i: i,
        a: a,
        b: b,
        c: c
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
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: K<number | null>;
    b: K<number[]>;
    c: K_JSON<E_JSON | null>;
    d: K_JSON<E_JSON[]>;
};
""", """
export function S_decode(json: S_JSON): S {
    const a = json.a as K<number | null>;
    const b = json.b as K<number[]>;
    const c = K_decode<E | null, E_JSON | null>(json.c, (json: E_JSON | null): E | null => {
        return Optional_decode<E, E_JSON>(json, E_decode);
    });
    const d = K_decode<E[], E_JSON[]>(json.d, (json: E_JSON[]): E[] => {
        return Array_decode<E, E_JSON>(json, E_decode);
    });
    return {
        a: a,
        b: b,
        c: c,
        d: d
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
} & TagRecord<"S", [T]>;
""", """
export type S_JSON<T_JSON> = {
    a: K_JSON<T_JSON | null>;
    b: K_JSON<T_JSON[]>;
};
""", """
export function S_decode<T, T_JSON>(json: S_JSON<T_JSON>, T_decode: (json: T_JSON) => T): S<T> {
    const a = K_decode<T | null, T_JSON | null>(json.a, (json: T_JSON | null): T | null => {
        return Optional_decode<T, T_JSON>(json, T_decode);
    });
    const b = K_decode<T[], T_JSON[]>(json.b, (json: T_JSON[]): T[] => {
        return Array_decode<T, T_JSON>(json, T_decode);
    });
    return {
        a: a,
        b: b
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
} & TagRecord<"E", [T]>;
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
        const _0 = T_decode(j._0);
        return {
            kind: "a",
            a: {
                _0: _0
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
