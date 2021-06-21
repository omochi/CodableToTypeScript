import SwiftTypeReader
import TSCodeModule

struct DependencyScanner {
    var standardTypes: Set<String>

    func callAsFunction(code: TSCode) -> [String] {
        Impl(
            standardTypes: standardTypes,
            code: code
        ).run()
    }
}

private final class Impl {
    let code: TSCode

    init(
        standardTypes: Set<String>,
        code: TSCode
    ) {
        self.standardTypes = standardTypes
        self.code = code
    }

    let standardTypes: Set<String>
    var deps: Set<String> = []

    func run() -> [String] {
        for decl in code.decls {
            switch decl {
            case .typeDecl(let decl):
                process(type: decl.type)
            default:
                break
            }
        }

        return deps.sorted { $0 < $1 }
    }

    private func process(type: TSType) {
        switch type {
        case .named(let t):
            add(dep: t.name)
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
        guard !standardTypes.contains(dep) else {
            return
        }
        deps.insert(dep)
    }
}
