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
export type S$JSON<T$JSON> = {
    a: T$JSON;
};
""", """
export function S_decode<T, T$JSON>(json: S$JSON<T$JSON>, T_decode: (json: T$JSON) => T): S<T> {
    const a = T_decode(json.a);
    return {
        a: a
    };
}
"""]
        )

        try assertGenerate(
            source: """
struct S<T> {
    var a: Int
}
""",
            expecteds: ["""
export type S<T> = {
    a: number;
} & TagRecord<"S", [T]>;
"""],
            unexpecteds: ["""
export type S$JSON<T$JSON>
""", """
export function S_decode<T, T$JSON>
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
export type S$JSON
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
export type S$JSON = {
    a: K$JSON<E$JSON>;
};
""", """
export function S_decode(json: S$JSON): S {
    const a = K_decode<E, E$JSON>(json.a, E_decode);
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
export type S$JSON<A$JSON, B$JSON> = {
    a: A$JSON;
    b: B$JSON;
};
""", """
export function S_decode<
    A,
    A$JSON,
    B,
    B$JSON
>(json: S$JSON<A$JSON, B$JSON>, A_decode: (json: A$JSON) => A, B_decode: (json: B$JSON) => B): S<A, B> {
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
export type S$JSON<A$JSON, B$JSON, C$JSON> = {
    a: A$JSON;
    b: B$JSON;
    c: C$JSON;
};
""", """
export function S_decode<
    A,
    A$JSON,
    B,
    B$JSON,
    C,
    C$JSON
>(
    json: S$JSON<A$JSON, B$JSON, C$JSON>,
    A_decode: (json: A$JSON) => A,
    B_decode: (json: B$JSON) => B,
    C_decode: (json: C$JSON) => C
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
export type S$JSON<T$JSON> = {
    a: K$JSON<T$JSON>;
    b: L$JSON<T$JSON>;
    c: X<T$JSON>;
};
""", """
export function S_decode<T, T$JSON>(json: S$JSON<T$JSON>, T_decode: (json: T$JSON) => T): S<T> {
    const a = K_decode<T, T$JSON>(json.a, T_decode);
    const b = L_decode<T, T$JSON>(json.b, T_decode);
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
export type S$JSON<T$JSON, U$JSON> = {
    a: K$JSON<T$JSON>;
    b: K$JSON<U$JSON>;
    c: L$JSON<T$JSON, T$JSON>;
    d: L$JSON<T$JSON, U$JSON>;
};
""", """
export function S_decode<
    T,
    T$JSON,
    U,
    U$JSON
>(json: S$JSON<T$JSON, U$JSON>, T_decode: (json: T$JSON) => T, U_decode: (json: U$JSON) => U): S<T, U> {
    const a = K_decode<T, T$JSON>(json.a, T_decode);
    const b = K_decode<U, U$JSON>(json.b, U_decode);
    const c = L_decode<
        T,
        T$JSON,
        T,
        T$JSON
    >(json.c, T_decode, T_decode);
    const d = L_decode<
        T,
        T$JSON,
        U,
        U$JSON
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
export type S$JSON = {
    i: K<number>;
    a: K<A>;
    b: K$JSON<B$JSON>;
    c: K<C>;
};
""", """
export function S_decode(json: S$JSON): S {
    const i = json.i as K<number>;
    const a = json.a as K<A>;
    const b = K_decode<B, B$JSON>(json.b, B_decode);
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
export type S$JSON = {
    a: K<number | null>;
    b: K<number[]>;
    c: K$JSON<E$JSON | null>;
    d: K$JSON<E$JSON[]>;
};
""", """
export function S_decode(json: S$JSON): S {
    const a = json.a as K<number | null>;
    const b = json.b as K<number[]>;
    const c = K_decode<E | null, E$JSON | null>(json.c, (json: E$JSON | null): E | null => {
        return Optional_decode<E, E$JSON>(json, E_decode);
    });
    const d = K_decode<E[], E$JSON[]>(json.d, (json: E$JSON[]): E[] => {
        return Array_decode<E, E$JSON>(json, E_decode);
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
export type S$JSON<T$JSON> = {
    a: K$JSON<T$JSON | null>;
    b: K$JSON<T$JSON[]>;
};
""", """
export function S_decode<T, T$JSON>(json: S$JSON<T$JSON>, T_decode: (json: T$JSON) => T): S<T> {
    const a = K_decode<T | null, T$JSON | null>(json.a, (json: T$JSON | null): T | null => {
        return Optional_decode<T, T$JSON>(json, T_decode);
    });
    const b = K_decode<T[], T$JSON[]>(json.b, (json: T$JSON[]): T[] => {
        return Array_decode<T, T$JSON>(json, T_decode);
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
export type E$JSON<T$JSON> = {
    a: {
        _0: T$JSON;
    };
};
""","""
export function E_decode<T, T$JSON>(json: E$JSON<T$JSON>, T_decode: (json: T$JSON) => T): E<T> {
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

    func testParentGenericParameter() throws {
        try assertGenerate(
            source: """
struct S<X> {
    struct K {
        var x: X
    }
}
""",
            typeSelector: .name("K", recursive: true),
            expecteds: ["""
export type S_K<X> = {
    x: X;
} & TagRecord<"S_K", [X]>;
""", """
export type S_K$JSON<X$JSON> = {
    x: X$JSON;
};
"""])
    }

    func testParentGenericParameterCoding() throws {
        try assertGenerate(
            source: """
struct S<X> {
    struct K {
        var x: X
    }
    typealias K2 = K
}

enum E { case a }

struct U {
    var k: S<E>.K
    var k2: S<E>.K2
    var k3: S<Int>.K
}
""",
            typeSelector: .name("U", recursive: true),
            expecteds: ["""
export type U = {
    k: S_K<E>;
    k2: S_K2<E>;
    k3: S_K<number>;
} & TagRecord<"U">;
""", """
export type U$JSON = {
    k: S_K$JSON<E$JSON>;
    k2: S_K2$JSON<E$JSON>;
    k3: S_K<number>;
};
""", """
export function U_decode(json: U$JSON): U {
    const k = S_K_decode<E, E$JSON>(json.k, E_decode);
    const k2 = S_K2_decode<E, E$JSON>(json.k2, E_decode);
    const k3 = json.k3 as S_K<number>;
    return {
        k: k,
        k2: k2,
        k3: k3
    };
}
"""])
    }

    func testNestedParentGenericParameter() throws {
        try assertGenerate(
            source: """
struct S<X> {
    struct T {
        struct K {
            var x: X
        }
    }
}
""",
            typeSelector: .name("K", recursive: true),
            expecteds: ["""
export type S_T_K<X> = {
    x: X;
} & TagRecord<"S_T_K", [X]>;
"""])
    }

    func testUnusedParentGenericParameter() throws {
        try assertGenerate(
            source: """
struct S<X> {
    struct K {
        var x: Int
    }
}
""",
            typeSelector: .name("K", recursive: true),
            expecteds: ["""
export type S_K<X> = {
    x: number;
} & TagRecord<"S_K", [X]>;
"""])
    }

    func testComplexNestedParentGeneric() throws {
        try assertGenerate(
            source: """
struct S<T> {
    struct G<U> {
         var t: T
         var u: U
    }
}

enum E { case o }

struct K<T> {
    var k: S<E>.G<T>
}
""",
            typeSelector: .name("K", recursive: true),
            expecteds: ["""
export type K<T> = {
    k: S_G<E, T>;
} & TagRecord<"K", [T]>;
""", """
export type K$JSON<T$JSON> = {
    k: S_G$JSON<E$JSON, T$JSON>;
};
""", """
export function K_decode<T, T$JSON>(json: K$JSON<T$JSON>, T_decode: (json: T$JSON) => T): K<T> {
    const k = S_G_decode<
        E,
        E$JSON,
        T,
        T$JSON
    >(json.k, E_decode, T_decode);
    return {
        k: k
    };
}
""", """
export function K_encode<T, T$JSON>(entity: K<T>, T_encode: (entity: T) => T$JSON): K$JSON<T$JSON> {
    const k = S_G_encode<
        E,
        E$JSON,
        T,
        T$JSON
    >(entity.k, identity, T_encode);
    return {
        k: k
    };
}
"""]
        )
    }
}
