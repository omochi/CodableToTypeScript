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
};
""", """
export type S_JSON = {
    a: number;
    b: string;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: json.a,
        b: json.b
    };
}
"""
            ]
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
};
""", """
export type S_JSON = {
    a: number;
    b: E_JSON;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        a: json.a,
        b: E_decode(json.b)
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
};
""", """
export type S_JSON = {
    e1?: E_JSON;
    e2?: E_JSON | null;
    e3?: E_JSON | null;
};
""", """
export function S_decode(json: S_JSON): S {
    return {
        e1: OptionalField_decode(json.e1, E_decode),
        e2: OptionalField_decode(json.e2, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        }),
        e3: OptionalField_decode(json.e3, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        })
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
            expecteds: ["""
export function S_decode(json: S_JSON): S {
    return {
        e1: json.e1,
        e2: json.e2,
        e3: json.e3
    };
}
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
    return {
        e1: Array_decode(json.e1, E_decode),
        e2: Array_decode(json.e2, (json: E_JSON[]): E[] => {
            return Array_decode(json, E_decode);
        }),
        e3: Array_decode(json.e3, (json: E_JSON[][]): E[][] => {
            return Array_decode(json, (json: E_JSON[]): E[] => {
                return Array_decode(json, E_decode);
            });
        })
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
            expecteds: ["""
export function S_decode(json: S_JSON): S {
    return {
        e1: json.e1,
        e2: json.e2,
        e3: json.e3
    };
}
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
    return {
        e1: OptionalField_decode(json.e1, (json: E_JSON[]): E[] => {
            return Array_decode(json, E_decode);
        }),
        e2: Array_decode(json.e2, (json: E_JSON | null): E | null => {
            return Optional_decode(json, E_decode);
        }),
        e3: OptionalField_decode(json.e3, (json: E_JSON[]): E[] => {
            return Array_decode(json, E_decode);
        }),
        e4: OptionalField_decode(json.e4, (json: (E_JSON | null)[]): (E | null)[] => {
            return Array_decode(json, (json: E_JSON | null): E | null => {
                return Optional_decode(json, E_decode);
            });
        })
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
            typeSelector: .name("S"),
            expecteds: ["""
export function S_decode(json: S_JSON): S {
    return {
        e1: Dictionary_decode(json.e1, E_decode),
        e2: Dictionary_decode(json.e2, (json: (E_JSON | null)[]): (E | null)[] => {
            return Array_decode(json, (json: E_JSON | null): E | null => {
                return Optional_decode(json, E_decode);
            });
        }),
        e3: json.e3
    };
}
"""]
        )
    }
}
