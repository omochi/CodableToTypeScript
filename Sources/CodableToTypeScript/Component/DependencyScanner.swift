import SwiftTypeReader
import TSCodeModule

public struct DependencyScanner {
    public init(knownNames: Set<String>) {
        self.knownNames = knownNames
    }

    public var knownNames: Set<String>

    public func scan(code: TSCode) -> [String] {
        let impl = Impl(
            knownNames: knownNames
        )
        return impl.run(code: code)
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
            function.genericParameters.map { $0.name }
        )
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

        let paramNames = type.genericParameters.map { $0.name }
        scope.knownNames.formUnion(paramNames)
        
        return true
    }

    func visitEnd(type: TSTypeDecl) {
        pop()
    }

    func visit(for: TSForStmt) -> Bool {
        push()

        scope.knownNames.insert(`for`.name)

        return true
    }

    func visitEnd(for: TSForStmt) {
        pop()
    }

    func visit(closure: TSClosureExpr) -> Bool {
        push()

        scope.knownNames.formUnion(
            closure.parameters.map { $0.name }
        )

        return true
    }

    func visitEnd(closure: TSClosureExpr) {
        pop()
    }

    func visit(identifier: TSIdentifierExpr) -> Bool {
        check(identifier.name)
        return true
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

    func visit(`var`: TSVarDecl) -> Bool {
        names.insert(`var`.name)
        return false
    }
}
