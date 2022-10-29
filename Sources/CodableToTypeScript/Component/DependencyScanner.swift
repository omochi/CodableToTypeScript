import SwiftTypeReader
import TSCodeModule

struct DependencyScanner {
    var knownNames: Set<String>

    func scan(code: TSCode) -> [String] {
        Impl(
            knownNames: knownNames
        ).run(code: code)
    }
}

private final class Impl: TSTreeVisitor {
    struct Scope {
        var knownNames: Set<String>
    }

    init(
        knownNames: Set<String>
    ) {
        self.scopes = [
            Scope(knownNames: knownNames)
        ]
    }

    var scopes: [Scope]
    var deps: Set<String> = []

    private var scope: Scope {
        get { scopes.last! }
        set { scopes[scopes.count - 1] = newValue }
    }

    func run(code: TSCode) -> [String] {
        walk(code: code)

        return deps.sorted { $0 < $1 }
    }

    private func push() {
        scopes.append(scope)
    }

    private func pop() {
        scopes.removeLast()
    }

    private func check(_ dep: String) {
        if scope.knownNames.contains(dep) {
            return
        }

        deps.insert(dep)
    }

    func visit(items: [TSBlockItem]) -> Bool {
        let collector = NameCollector()
        let names = collector.collect(items: items)

        push()
        scope.knownNames.formUnion(names)

        return true
    }

    func visitEnd(items: [TSBlockItem]) {
        pop()
    }

    func visit(function: TSFunctionDecl) -> Bool {
        push()
        scope.knownNames.formUnion(
            function.parameters.map { $0.name }
        )
        return true
    }

    func visitEnd(function: TSFunctionDecl) {
        pop()
    }

    func visit(type: TSTypeDecl) -> Bool {
        push()

        let paramNames = type.genericParameters.compactMap { $0.type.named?.name }
        scope.knownNames.formUnion(paramNames)
        
        return true
    }

    func visitEnd(type: TSTypeDecl) {
        pop()
    }

    func visit(identifier: TSIdentifierExpr) {
        check(identifier.name)
    }

    func visit(named: TSNamedType) -> Bool {
        check(named.name)
        return true
    }

    func visit(nested: TSNestedType) -> Bool {
        check(nested.namespace)
        return false
    }

    func visit(objectField: TSObjectField) -> Bool {
        visitImpl(expr: objectField.value)
        return false
    }
}

private final class NameCollector: TSTreeVisitor {
    init() {}

    private var names: Set<String> = []

    func collect(items: [TSBlockItem]) -> Set<String> {
        names.removeAll()
        for item in items {
            walk(item: item)
        }
        return names
    }

    func visit(type: TSTypeDecl) -> Bool {
        names.insert(type.name)
        return false
    }

    func visit(function: TSFunctionDecl) -> Bool {
        names.insert(function.name)
        return false
    }

    func visit(namespace: TSNamespaceDecl) -> Bool {
        names.insert(namespace.name)
        return false
    }
}
