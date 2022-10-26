import SwiftTypeReader
import TSCodeModule

struct DependencyScanner {
    var standardTypes: Set<String>

    func callAsFunction(decls: [TSDecl]) -> [String] {
        Impl(
            standardTypes: standardTypes,
            decls: decls
        ).run()
    }
}

private final class Impl {
    init(
        standardTypes: Set<String>,
        decls: [TSDecl]
    ) {
        self.standardTypes = standardTypes
        self.decls = decls
    }

    let standardTypes: Set<String>
    let decls: [TSDecl]
    var ignores: Set<String> = []
    var deps: Set<String> = []

    func run() -> [String] {
        for decl in decls {
            switch decl {
            case .typeDecl(let decl):
                stackIgnores {
                    ignores.insert(decl.name)
                    for p in decl.genericParameters {
                        ignores.insert(p)
                    }

                    process(type: decl.type)
                }
            default:
                break
            }
        }

        return deps.sorted { $0 < $1 }
    }

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
            add(dep: t.name)
            for arg in t.genericArguments {
                process(type: arg)
            }
        case .nested(let t):
            add(dep: t.namespace)
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

    private func add(dep: String) {
        guard !standardTypes.contains(dep),
              !ignores.contains(dep) else {
            return
        }
        deps.insert(dep)
    }
}
