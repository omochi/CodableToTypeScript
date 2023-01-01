import XCTest
import CodableToTypeScript

final class GenerateStructTests: GenerateTestCaseBase {
    func testSimple() throws {
        try assertGenerate(
            source: """
struct S {
    var a: Int
    var b: String
}
""",
            expecteds: ["""
export type S = {
    a: number;
    b: string;
} & TagRecord<"S">;
"""
            ],
            unexpecteds: ["""
export function S_decode
"""]
        )
    }

    func testEmptyDecode() throws {
        try assertGenerate(
            source: """
struct K {
    var a: Int
}
struct S {
    var k: K
}
""",
            typeSelector: .name("S")
        )
    }

    func testEnumInStruct() throws {
        try assertGenerate(
            source: """
enum E {
    case a
}

struct S {
    var a: Int
    var b: E
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S = {
    a: number;
    b: E;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: number;
    b: E_JSON;
};
""", """
export function S_decode(json: S_JSON): S {
    const a = json.a;
    const b = E_decode(json.b);
    return {
        a: a,
        b: b
    };
}
"""]
        )
    }

    func testDecodeOptional() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    var e1: E?
    var e2: E??
    var e3: E???
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S = {
    e1?: E;
    e2?: E | null;
    e3?: E | null;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    e1?: E_JSON;
    e2?: E_JSON | null;
    e3?: E_JSON | null;
};
""", """
export function S_decode(json: S_JSON): S {
    const e1 = OptionalField_decode(json.e1, E_decode);
    const e2 = OptionalField_decode(json.e2, (json: E_JSON | null): E | null => {
        return Optional_decode(json, E_decode);
    });
    const e3 = OptionalField_decode(json.e3, (json: E_JSON | null): E | null => {
        return Optional_decode(json, E_decode);
    });
    return {
        e1: e1,
        e2: e2,
        e3: e3
    };
}
"""
            ]
        )
    }

    func testEmptyDecodeOptional() throws {
        try assertGenerate(
            source: """
struct S {
    var e1: Int?
    var e2: Int??
    var e3: Int???
""",
            typeSelector: .name("S"),
            unexpecteds: ["""
export function S_decode
"""
            ]
        )
    }


    func testDecodeArray() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    var e1: [E]
    var e2: [[E]]
    var e3: [[[E]]]
}
"""
            ,
            typeSelector: .name("S"),
            expecteds: ["""
export function S_decode(json: S_JSON): S {
    const e1 = Array_decode(json.e1, E_decode);
    const e2 = Array_decode(json.e2, (json: E_JSON[]): E[] => {
        return Array_decode(json, E_decode);
    });
    const e3 = Array_decode(json.e3, (json: E_JSON[][]): E[][] => {
        return Array_decode(json, (json: E_JSON[]): E[] => {
            return Array_decode(json, E_decode);
        });
    });
    return {
        e1: e1,
        e2: e2,
        e3: e3
    };
}
"""]
        )
    }

    func testEmptyDecodeArray() throws {
        try assertGenerate(
            source: """
struct S {
    var e1: [Int]
    var e2: [[Int]]
    var e3: [[[Int]]]
}
"""
            ,
            typeSelector: .name("S"),
            unexpecteds: ["""
export function S_decode
"""]
        )
    }

    func testDecodeOptionalAndArray() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    var e1: [E]?
    var e2: [E?]
    var e3: [E]?
    var e4: [E?]?
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export function S_decode(json: S_JSON): S {
    const e1 = OptionalField_decode(json.e1, (json: E_JSON[]): E[] => {
        return Array_decode(json, E_decode);
    });
    const e2 = Array_decode(json.e2, (json: E_JSON | null): E | null => {
        return Optional_decode(json, E_decode);
    });
    const e3 = OptionalField_decode(json.e3, (json: E_JSON[]): E[] => {
        return Array_decode(json, E_decode);
    });
    const e4 = OptionalField_decode(json.e4, (json: (E_JSON | null)[]): (E | null)[] => {
        return Array_decode(json, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        });
    });
    return {
        e1: e1,
        e2: e2,
        e3: e3,
        e4: e4
    };
}
"""]
        )
    }

    func testDecodeDictionary() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    var e1: [String: E]
    var e2: [String: [E?]]
    var e3: [String: Int]
}
""",
            expecteds: ["""
export type S = {
    e1: Map<string, E>;
    e2: Map<string, (E | null)[]>;
    e3: Map<string, number>;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    e1: {
        [key: string]: E_JSON;
    };
    e2: {
        [key: string]: (E_JSON | null)[];
    };
    e3: {
        [key: string]: number;
    };
};
""", """
export function S_decode(json: S_JSON): S {
    const e1 = Dictionary_decode(json.e1, E_decode);
    const e2 = Dictionary_decode(json.e2, (json: (E_JSON | null)[]): (E | null)[] => {
        return Array_decode(json, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        });
    });
    const e3 = Dictionary_decode(json.e3, identity);
    return {
        e1: e1,
        e2: e2,
        e3: e3
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    const e1 = Dictionary_encode(entity.e1, identity);
    const e2 = Dictionary_encode(entity.e2, identity);
    const e3 = Dictionary_encode(entity.e3, identity);
    return {
        e1: e1,
        e2: e2,
        e3: e3
    };
}
"""]
        )
    }

    func testDoubleDictionary() throws {
        try assertGenerate(
            source: """
struct S {
    var a: [String: [String: Int]]
}
""",
            expecteds: ["""
export type S = {
    a: Map<string, Map<string, number>>;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a: {
        [key: string]: {
            [key: string]: number;
        };
    };
};
""", """
export function S_decode(json: S_JSON): S {
    const a = Dictionary_decode(json.a, (json: {
        [key: string]: number;
    }): Map<string, number> => {
        return Dictionary_decode(json, identity);
    });
    return {
        a: a
    };
}
""", """
export function S_encode(entity: S): S_JSON {
    const a = Dictionary_encode(entity.a, (entity: Map<string, number>): {
        [key: string]: number;
    } => {
        return Dictionary_encode(entity, identity);
    });
    return {
        a: a
    };
}
"""
            ]
        )
    }

    func testRecursive() throws {
        try assertGenerate(
            source: """
struct S {
    var a: S?
}
""",
            expecteds: ["""
export type S = {
    a?: S;
} & TagRecord<"S">;
""", """
export type S_JSON = {
    a?: S_JSON;
};
""", """
export function S_decode(json: S_JSON): S {
    const a = OptionalField_decode(json.a, S_decode);
    return {
        a: a
    };
}
"""
            ]
        )
    }

    func testUnresolvedFailure() throws {
        XCTAssertThrowsError(
            try assertGenerate(
                source: """
struct S {
    var a: A
}
""")
        )
    }
}
