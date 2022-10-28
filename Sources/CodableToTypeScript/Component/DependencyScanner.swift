import SwiftTypeReader
import TSCodeModule

struct DependencyScanner {
    var standardTypes: Set<String>

    func scan(code: TSCode) -> [String] {
        Impl(
            standardTypes: standardTypes,
            code: code
        ).run()
    }
}

private final class Impl: TSTreeVisitor {
    init(
        standardTypes: Set<String>,
        code: TSCode
    ) {
        self.standardTypes = standardTypes
        self.code = code
    }

    let standardTypes: Set<String>
    let code: TSCode
    var ignores: Set<String> = []
    var deps: Set<String> = []

    func run() -> [String] {
        walk(code: code)

        return deps.sorted { $0 < $1 }
    }

//    func run2() -> [String] {
//        for decl in decls {
//            switch decl {
//            case .type(let decl):
//                stackIgnores {
//                    ignores.insert(decl.name)
//                    for p in decl.genericParameters.items {
//                        ignores.insert(p)
//                    }
//
//                    process(type: decl.type)
//                }
//            default:
//                break
//            }
//        }
//
//        return deps.sorted { $0 < $1 }
//    }

    private func stackIgnores<R>(_ f: () throws -> R) rethrows -> R {
        let ignores = self.ignores
        defer {
            self.ignores = ignores
        }
        return try f()
    }

    private func process(type: TSType) {
        switch type {
        case .named(let t):
            add(t.name)
            for arg in t.genericArguments {
                process(type: arg)
            }
        case .nested(let t):
            add(t.namespace)
        case .record(let t):
            for field in t.fields {
                process(type: field.type)
            }
        case .union(let t):
            for item in t.items {
                process(type: item)
            }
        case .array(let t):
            process(type: t.element)
        case .dictionary(let t):
            process(type: t.element)
        case .stringLiteral:
            break
        }
    }

    private func add(_ dep: String) {
        guard !standardTypes.contains(dep),
              !ignores.contains(dep) else {
            return
        }
        deps.insert(dep)
    }
}
