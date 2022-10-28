public protocol TSTreeVisitor {
    func walk(code: TSCode)
    func walk(item: TSBlockItem)

    func visit(item: TSBlockItem) -> Bool
    func visitEnd(item: TSBlockItem)

    func visit(function: TSFunctionDecl) -> Bool
    func visitEnd(function: TSFunctionDecl)

    func visit(import: TSImportDecl)

    func visit(namespace: TSNamespaceDecl) -> Bool
    func visitEnd(namespace: TSNamespaceDecl)

    func visit(type: TSTypeDecl)

    func visit(`var`: TSVarDecl)

    func visit(custom: TSCustomDecl)

    func visit(block: TSBlockStmt) -> Bool
    func visitEnd(block: TSBlockStmt)

    func visit(if: TSIfStmt) -> Bool
    func visitEnd(if: TSIfStmt)

    func visit(return: TSReturnStmt) -> Bool
    func visitEnd(return: TSReturnStmt)

    func visit(throw: TSThrowStmt) -> Bool
    func visitEnd(throw: TSThrowStmt)

    func visit(custom: TSCustomStmt)

    func visit(call: TSCallExpr) -> Bool
    func visitEnd(call: TSCallExpr)

    func visit(identifier: TSIdentifierExpr)

    func visit(infixOperator: TSInfixOperatorExpr) -> Bool
    func visitEnd(infixOperator: TSInfixOperatorExpr)

    func visit(memberAccess: TSMemberAccessExpr) -> Bool
    func visitEnd(memberAccess: TSMemberAccessExpr)

    func visit(new: TSNewExpr) -> Bool
    func visitEnd(new: TSNewExpr)

    func visit(object: TSObjectExpr) -> Bool
    func visitEnd(object: TSObjectExpr)

    func visit(stringLiteral: TSStringLiteralExpr)

    func visit(custom: TSCustomExpr)

    func visit(array: TSArrayType) -> Bool
    func visitEnd(array: TSArrayType)

    func visit(dictionary: TSDictionaryType) -> Bool
    func visitEnd(dictionary: TSDictionaryType)

    func visit(named: TSNamedType) -> Bool
    func visitEnd(named: TSNamedType)

    func visit(nested: TSNestedType) -> Bool
    func visitEnd(nested: TSNestedType)

    func visit(record: TSRecordType) -> Bool
    func visitEnd(record: TSRecordType)

    func visit(stringLiteral: TSStringLiteralType)

    func visit(union: TSUnionType) -> Bool
    func visitEnd(union: TSUnionType)
}

extension TSTreeVisitor {
    public func walk(code: TSCode) {
        for item in code.items {
            walk(item: item)
        }
    }

    public func walk(item: TSBlockItem) {
        visitImpl(item: item)
    }

    private func visitImpl(item: TSBlockItem) {
        switch item {
        case .decl(let decl): visitImpl(decl: decl)
        case .stmt(let stmt): visitImpl(stmt: stmt)
        case .expr(let expr): visitImpl(expr: expr)
        }
    }

    private func visitImpl(decl: TSDecl) {
        switch decl {
        case .function(let d): visitImpl(function: d)
        case .import(let d): visit(import: d)
        case .namespace(let d): visitImpl(namespace: d)
        case .type(let d): visit(type: d)
        case .var(let d): visit(var: d)
        case .custom(let d): visit(custom: d)
        }
    }

    private func visitImpl(stmt: TSStmt) {
        switch stmt {
        case .block(let s): visitImpl(block: s)
        case .if(let s): visitImpl(if: s)
        case .return(let s): visitImpl(return: s)
        case .throw(let s): visitImpl(throw: s)
        case .custom(let s): visit(custom: s)
        }
    }

    private func visitImpl(expr: TSExpr) {
        switch expr {
        case .call(let e): visitImpl(call: e)
        case .identifier(let e): visit(identifier: e)
        case .infixOperator(let e): visitImpl(infixOperator: e)
        case .memberAccess(let e): visitImpl(memberAccess: e)
        case .new(let e): visitImpl(new: e)
        case .object(let e): visitImpl(object: e)
        case .stringLiteral(let e): visit(stringLiteral: e)
        case .custom(let e): visit(custom: e)
        }
    }

    private func visitImpl(type: TSType) {
        switch type {
        case .array(let t): visitImpl(array: t)
        case .dictionary(let t): visitImpl(dictionary: t)
        case .named(let t): visitImpl(named: t)
        case .nested(let t): visitImpl(nested: t)
        case .record(let t): visitImpl(record: t)
        case .stringLiteral(let t): visit(stringLiteral: t)
        case .union(let t): visitImpl(union: t)
        }
    }

    // MARK: single impls

    private func visitImpl(function: TSFunctionDecl) {
        if visit(function: function) {
            for item in function.items {
                visitImpl(item: item)
            }
        }
        visitEnd(function: function)
    }

    private func visitImpl(namespace: TSNamespaceDecl) {
        if visit(namespace: namespace) {
            for decl in namespace.decls {
                visitImpl(item: .decl(decl))
            }
        }
        visitEnd(namespace: namespace)
    }

    private func visitImpl(block: TSBlockStmt) {
        if visit(block: block) {
            for item in block.items {
                visitImpl(item: item)
            }
        }
        visitEnd(block: block)
    }

    private func visitImpl(if: TSIfStmt) {
        if visit(if: `if`) {
            visitImpl(stmt: `if`.then)
            if let s = `if`.else {
                visitImpl(stmt: s)
            }
        }
        visitEnd(if: `if`)
    }

    private func visitImpl(return: TSReturnStmt) {
        if visit(return: `return`) {
            visitImpl(expr: `return`.expr)
        }
        visitEnd(return: `return`)
    }

    private func visitImpl(throw: TSThrowStmt) {
        if visit(throw: `throw`) {
            visitImpl(expr: `throw`.expr)
        }
        visitEnd(throw: `throw`)
    }

    private func visitImpl(call: TSCallExpr) {
        if visit(call: call) {
            visitImpl(expr: call.callee)
            for arg in call.arguments {
                visitImpl(expr: arg)
            }
        }
        visitEnd(call: call)
    }

    private func visitImpl(infixOperator: TSInfixOperatorExpr) {
        if visit(infixOperator: infixOperator) {
            visitImpl(expr: infixOperator.left)
            visitImpl(expr: infixOperator.right)
        }
        visitEnd(infixOperator: infixOperator)
    }

    private func visitImpl(memberAccess: TSMemberAccessExpr) {
        if visit(memberAccess: memberAccess) {
            visitImpl(expr: memberAccess.base)
        }
        visitEnd(memberAccess: memberAccess)
    }

    private func visitImpl(new: TSNewExpr) {
        if visit(new: new) {
            visitImpl(expr: new.callee)
            for arg in new.arguments {
                visitImpl(expr: arg)
            }
        }
        visitEnd(new: new)
    }

    private func visitImpl(object: TSObjectExpr) {
        if visit(object: object) {
            for field in object.fields {
                visitImpl(expr: field.name)
                visitImpl(expr: field.value)
            }
        }
        visitEnd(object: object)
    }

    private func visitImpl(array: TSArrayType) {
        if visit(array: array) {
            visitImpl(type: array.element)
        }
        visitEnd(array: array)
    }

    private func visitImpl(dictionary: TSDictionaryType) {
        if visit(dictionary: dictionary) {
            visitImpl(type: dictionary.element)
        }
        visitEnd(dictionary: dictionary)
    }

    private func visitImpl(named: TSNamedType) {
        if visit(named: named) {
            for t in named.genericArguments {
                visitImpl(type: t)
            }
        }
        visitEnd(named: named)
    }

    private func visitImpl(nested: TSNestedType) {
        if visit(nested: nested) {
            visitImpl(type: nested.type)
        }
        visitEnd(nested: nested)
    }

    private func visitImpl(record: TSRecordType) {
        if visit(record: record) {
            for field in record.fields {
                visitImpl(type: field.type)
            }
        }
        visitEnd(record: record)
    }

    private func visitImpl(union: TSUnionType) {
        if visit(union: union) {
            for item in union.items {
                visitImpl(type: item)
            }
        }
        visitEnd(union: union)
    }

    // MARK: default impl for user API

    public func visit(item: TSBlockItem) -> Bool { true }
    public func visitEnd(item: TSBlockItem) {}
    public func visit(function: TSFunctionDecl) -> Bool { true }
    public func visitEnd(function: TSFunctionDecl) {}
    public func visit(import: TSImportDecl) {}
    public func visit(namespace: TSNamespaceDecl) -> Bool { true }
    public func visitEnd(namespace: TSNamespaceDecl) {}
    public func visit(type: TSTypeDecl) {}
    public func visit(`var`: TSVarDecl) {}
    public func visit(custom: TSCustomDecl) {}
    public func visit(block: TSBlockStmt) -> Bool { true }
    public func visitEnd(block: TSBlockStmt) {}
    public func visit(if: TSIfStmt) -> Bool { true }
    public func visitEnd(if: TSIfStmt) {}
    public func visit(return: TSReturnStmt) -> Bool { true }
    public func visitEnd(return: TSReturnStmt) {}
    public func visit(throw: TSThrowStmt) -> Bool { true }
    public func visitEnd(throw: TSThrowStmt) {}
    public func visit(custom: TSCustomStmt) {}
    public func visit(call: TSCallExpr) -> Bool { true }
    public func visitEnd(call: TSCallExpr) {}
    public func visit(identifier: TSIdentifierExpr) {}
    public func visit(infixOperator: TSInfixOperatorExpr) -> Bool { true }
    public func visitEnd(infixOperator: TSInfixOperatorExpr) {}
    public func visit(memberAccess: TSMemberAccessExpr) -> Bool { true }
    public func visitEnd(memberAccess: TSMemberAccessExpr) {}
    public func visit(new: TSNewExpr) -> Bool { true }
    public func visitEnd(new: TSNewExpr) {}
    public func visit(object: TSObjectExpr) -> Bool { true }
    public func visitEnd(object: TSObjectExpr) {}
    public func visit(stringLiteral: TSStringLiteralExpr) {}
    public func visit(custom: TSCustomExpr) {}
    public func visit(array: TSArrayType) -> Bool { true }
    public func visitEnd(array: TSArrayType) {}
    public func visit(dictionary: TSDictionaryType) -> Bool { true }
    public func visitEnd(dictionary: TSDictionaryType) {}
    public func visit(named: TSNamedType) -> Bool { true }
    public func visitEnd(named: TSNamedType) {}
    public func visit(nested: TSNestedType) -> Bool { true }
    public func visitEnd(nested: TSNestedType) {}
    public func visit(record: TSRecordType) -> Bool { true }
    public func visitEnd(record: TSRecordType) {}
    public func visit(stringLiteral: TSStringLiteralType) {}
    public func visit(union: TSUnionType) -> Bool { true }
    public func visitEnd(union: TSUnionType) {}
}
