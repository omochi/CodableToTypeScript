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
export type S$JSON = {
    a: number;
    b: E$JSON;
};
""", """
export function S_decode(json: S$JSON): S {
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
export type S$JSON = {
    e1?: E$JSON;
    e2?: E$JSON | null;
    e3?: E$JSON | null;
};
""", """
export function S_decode(json: S$JSON): S {
    const e1 = OptionalField_decode<E, E$JSON>(json.e1, E_decode);
    const e2 = OptionalField_decode<E | null, E$JSON | null>(json.e2, (json: E$JSON | null): E | null => {
        return Optional_decode<E, E$JSON>(json, E_decode);
    });
    const e3 = OptionalField_decode<E | null, E$JSON | null>(json.e3, (json: E$JSON | null): E | null => {
        return Optional_decode<E, E$JSON>(json, E_decode);
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
export function S_decode(json: S$JSON): S {
    const e1 = Array_decode<E, E$JSON>(json.e1, E_decode);
    const e2 = Array_decode<E[], E$JSON[]>(json.e2, (json: E$JSON[]): E[] => {
        return Array_decode<E, E$JSON>(json, E_decode);
    });
    const e3 = Array_decode<E[][], E$JSON[][]>(json.e3, (json: E$JSON[][]): E[][] => {
        return Array_decode<E[], E$JSON[]>(json, (json: E$JSON[]): E[] => {
            return Array_decode<E, E$JSON>(json, E_decode);
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
export function S_decode(json: S$JSON): S {
    const e1 = OptionalField_decode<E[], E$JSON[]>(json.e1, (json: E$JSON[]): E[] => {
        return Array_decode<E, E$JSON>(json, E_decode);
    });
    const e2 = Array_decode<E | null, E$JSON | null>(json.e2, (json: E$JSON | null): E | null => {
        return Optional_decode<E, E$JSON>(json, E_decode);
    });
    const e3 = OptionalField_decode<E[], E$JSON[]>(json.e3, (json: E$JSON[]): E[] => {
        return Array_decode<E, E$JSON>(json, E_decode);
    });
    const e4 = OptionalField_decode<(E | null)[], (E$JSON | null)[]>(json.e4, (json: (E$JSON | null)[]): (E | null)[] => {
        return Array_decode<E | null, E$JSON | null>(json, (json: E$JSON | null): E | null => {
            return Optional_decode<E, E$JSON>(json, E_decode);
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

    func testSet() throws {
        try assertGenerate(
            source: """
enum E { case a }

struct S {
    var e1: Set<E>
}
""",
            typeSelector: .name("S"),
            expecteds: ["""
export type S = {
    e1: Set<E>;
} & TagRecord<"S">;

export type S$JSON = {
    e1: E$JSON[];
};

export function S_decode(json: S$JSON): S {
    const e1 = Set_decode<E, E$JSON>(json.e1, E_decode);
    return {
        e1: e1
    };
}

export function S_encode(entity: S): S$JSON {
    const e1 = Set_encode<E, E$JSON>(entity.e1, identity);
    return {
        e1: e1
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
export type S$JSON = {
    e1: {
        [key: string]: E$JSON;
    };
    e2: {
        [key: string]: (E$JSON | null)[];
    };
    e3: {
        [key: string]: number;
    };
};
""", """
export function S_decode(json: S$JSON): S {
    const e1 = Dictionary_decode<E, E$JSON>(json.e1, E_decode);
    const e2 = Dictionary_decode<(E | null)[], (E$JSON | null)[]>(json.e2, (json: (E$JSON | null)[]): (E | null)[] => {
        return Array_decode<E | null, E$JSON | null>(json, (json: E$JSON | null): E | null => {
            return Optional_decode<E, E$JSON>(json, E_decode);
        });
    });
    const e3 = Dictionary_decode<number, number>(json.e3, identity);
    return {
        e1: e1,
        e2: e2,
        e3: e3
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    const e1 = Dictionary_encode<E, E$JSON>(entity.e1, identity);
    const e2 = Dictionary_encode<(E | null)[], (E$JSON | null)[]>(entity.e2, identity);
    const e3 = Dictionary_encode<number, number>(entity.e3, identity);
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
export type S$JSON = {
    a: {
        [key: string]: {
            [key: string]: number;
        };
    };
};
""", """
export function S_decode(json: S$JSON): S {
    const a = Dictionary_decode<Map<string, number>, {
        [key: string]: number;
    }>(json.a, (json: {
        [key: string]: number;
    }): Map<string, number> => {
        return Dictionary_decode<number, number>(json, identity);
    });
    return {
        a: a
    };
}
""", """
export function S_encode(entity: S): S$JSON {
    const a = Dictionary_encode<Map<string, number>, {
        [key: string]: number;
    }>(entity.a, (entity: Map<string, number>): {
        [key: string]: number;
    } => {
        return Dictionary_encode<number, number>(entity, identity);
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
        if true || true {
            throw XCTSkip("unsupported")
        }
        try assertGenerate(
            source: """
indirect enum E: Codable {
    case a(E)
    case none
}
"""
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

    func testStaticProperty() throws {
        try assertGenerate(
            source: """
struct S {
    static var k: Int = 0

    var a: Int
}
""",
            expecteds: ["""
export type S = {
    a: number;
} & TagRecord<"S">;
"""
            ]
        )
    }

    func testUnknownStaticProperty() throws {
        try assertGenerate(
            source: """
struct S {
    static var k: Unknown = 0

    var a: Int
}
""",
            expecteds: ["""
export type S = {
    a: number;
} & TagRecord<"S">;
"""
            ]
        )
    }

    func testConflictPropertyName() throws {
        try assertGenerate(
            source: """
struct S<T> {
    var entity: String
    var json: String
    var t: T
}
""",
            expecteds: ["""
export type S<T> = {
    entity: string;
    json: string;
    t: T;
} & TagRecord<"S", [T]>;
""",
                        // decode
"""
const json2 = json.json;
""", """
json: json2,
""",

                        // encode
"""
const entity2 = entity.entity;
""", """
entity: entity2,
"""
            ],
            unexpecteds: []
        )
    }
}
