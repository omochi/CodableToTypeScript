public protocol TSTreeVisitor {
    func visit(code: TSCode) -> Bool
    func visitEnd(code: TSCode)

    func visit(item: TSBlockItem) -> Bool
    func visitEnd(item: TSBlockItem)

    func visit(items: [TSBlockItem]) -> Bool
    func visitEnd(items: [TSBlockItem])

    func visit(function: TSFunctionDecl) -> Bool
    func visitEnd(function: TSFunctionDecl)

    func visit(import: TSImportDecl)

    func visit(namespace: TSNamespaceDecl) -> Bool
    func visitEnd(namespace: TSNamespaceDecl)

    func visit(type: TSTypeDecl) -> Bool
    func visitEnd(type: TSTypeDecl)

    func visit(`var`: TSVarDecl) -> Bool
    func visitEnd(`var`: TSVarDecl)

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

    func visit(closure: TSClosureExpr) -> Bool
    func visitEnd(closure: TSClosureExpr)

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

    func visit(recordField: TSRecordType.Field) -> Bool
    func visitEnd(recordField: TSRecordType.Field)

    func visit(stringLiteral: TSStringLiteralType)

    func visit(union: TSUnionType) -> Bool
    func visitEnd(union: TSUnionType)

    func visit(functionArgument: TSFunctionArgument) -> Bool
    func visitEnd(functionArgument: TSFunctionArgument)

    func visit(functionArguments: [TSFunctionArgument]) -> Bool
    func visitEnd(functionArguments: [TSFunctionArgument])

    func visit(functionParameter: TSFunctionParameter) -> Bool
    func visitEnd(functionParameter: TSFunctionParameter)

    func visit(functionParameters: [TSFunctionParameter]) -> Bool
    func visitEnd(functionParameters: [TSFunctionParameter])

    func visit(genericArgument: TSGenericArgument) -> Bool
    func visitEnd(genericArgument: TSGenericArgument)

    func visit(genericArguments: [TSGenericArgument]) -> Bool
    func visitEnd(genericArguments: [TSGenericArgument])

    func visit(genericParameter: TSGenericParameter) -> Bool
    func visitEnd(genericParameter: TSGenericParameter)

    func visit(genericParameters: [TSGenericParameter]) -> Bool
    func visitEnd(genericParameters: [TSGenericParameter])

    func visit(objectField: TSObjectField) -> Bool
    func visitEnd(objectField: TSObjectField)

    func visit(objectFields: [TSObjectField]) -> Bool
    func visitEnd(objectFields: [TSObjectField])
}

extension TSTreeVisitor {
    public func walk(code: TSCode) {
        visitImpl(code: code)
    }

    public func walk(item: TSBlockItem) {
        visitImpl(item: item)
    }

    // MARK: dispatchers

    public func visitImpl(code: TSCode) {
        if visit(code: code) {
            visitImpl(items: code.items)
        }
        visitEnd(code: code)
    }

    public func visitImpl(item: TSBlockItem) {
        if visit(item: item) {
            switch item {
            case .decl(let decl): visitImpl(decl: decl)
            case .stmt(let stmt): visitImpl(stmt: stmt)
            case .expr(let expr): visitImpl(expr: expr)
            }
        }
        visitEnd(item: item)
    }

    public func visitImpl(items: [TSBlockItem]) {
        if visit(items: items) {
            for item in items {
                visitImpl(item: item)
            }
        }
        visitEnd(items: items)
    }

    public func visitImpl(decl: TSDecl) {
        switch decl {
        case .function(let d): visitImpl(function: d)
        case .import(let d): visit(import: d)
        case .namespace(let d): visitImpl(namespace: d)
        case .type(let d): visitImpl(type: d)
        case .var(let d): visitImpl(var: d)
        case .custom(let d): visit(custom: d)
        }
    }

    public func visitImpl(stmt: TSStmt) {
        switch stmt {
        case .block(let s): visitImpl(block: s)
        case .if(let s): visitImpl(if: s)
        case .return(let s): visitImpl(return: s)
        case .throw(let s): visitImpl(throw: s)
        case .custom(let s): visit(custom: s)
        }
    }

    public func visitImpl(expr: TSExpr) {
        switch expr {
        case .call(let e): visitImpl(call: e)
        case .closure(let e): visitImpl(closure: e)
        case .identifier(let e): visit(identifier: e)
        case .infixOperator(let e): visitImpl(infixOperator: e)
        case .memberAccess(let e): visitImpl(memberAccess: e)
        case .new(let e): visitImpl(new: e)
        case .object(let e): visitImpl(object: e)
        case .stringLiteral(let e): visit(stringLiteral: e)
        case .custom(let e): visit(custom: e)
        }
    }

    public func visitImpl(type: TSType) {
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

    public func visitImpl(function: TSFunctionDecl) {
        if visit(function: function) {
            visitImpl(genericParameters: function.genericParameters)
            visitImpl(functionParameters: function.parameters)
            visitImpl(items: function.items)
        }
        visitEnd(function: function)
    }

    public func visitImpl(namespace: TSNamespaceDecl) {
        if visit(namespace: namespace) {
            for decl in namespace.decls {
                visitImpl(item: .decl(decl))
            }
        }
        visitEnd(namespace: namespace)
    }

    public func visitImpl(type: TSTypeDecl) {
        if visit(type: type) {
            visitImpl(genericParameters: type.genericParameters)
            visitImpl(type: type.type)
        }
        visitEnd(type: type)
    }

    public func visitImpl(`var`: TSVarDecl) {
        if visit(var: `var`) {
            if let expr = `var`.initializer {
                visitImpl(expr: expr)
            }
        }
        visitEnd(var: `var`)
    }

    public func visitImpl(block: TSBlockStmt) {
        if visit(block: block) {
            visitImpl(items: block.items)
        }
        visitEnd(block: block)
    }

    public func visitImpl(if: TSIfStmt) {
        if visit(if: `if`) {
            visitImpl(stmt: `if`.then)
            if let s = `if`.else {
                visitImpl(stmt: s)
            }
        }
        visitEnd(if: `if`)
    }

    public func visitImpl(return: TSReturnStmt) {
        if visit(return: `return`) {
            visitImpl(expr: `return`.expr)
        }
        visitEnd(return: `return`)
    }

    public func visitImpl(throw: TSThrowStmt) {
        if visit(throw: `throw`) {
            visitImpl(expr: `throw`.expr)
        }
        visitEnd(throw: `throw`)
    }

    public func visitImpl(call: TSCallExpr) {
        if visit(call: call) {
            visitImpl(expr: call.callee)
            visitImpl(functionArguments: call.arguments)
        }
        visitEnd(call: call)
    }

    public func visitImpl(closure: TSClosureExpr) {
        if visit(closure: closure) {
            visitImpl(functionParameters: closure.parameters)
            if let type = closure.returnType {
                visitImpl(type: type)
            }
            visitImpl(items: closure.items)
        }
        visitEnd(closure: closure)
    }

    public func visitImpl(infixOperator: TSInfixOperatorExpr) {
        if visit(infixOperator: infixOperator) {
            visitImpl(expr: infixOperator.left)
            visitImpl(expr: infixOperator.right)
        }
        visitEnd(infixOperator: infixOperator)
    }

    public func visitImpl(memberAccess: TSMemberAccessExpr) {
        if visit(memberAccess: memberAccess) {
            visitImpl(expr: memberAccess.base)
        }
        visitEnd(memberAccess: memberAccess)
    }

    public func visitImpl(new: TSNewExpr) {
        if visit(new: new) {
            visitImpl(expr: new.callee)
            visitImpl(functionArguments: new.arguments)
        }
        visitEnd(new: new)
    }

    public func visitImpl(object: TSObjectExpr) {
        if visit(object: object) {
            visitImpl(objectFields: object.fields)
        }
        visitEnd(object: object)
    }

    public func visitImpl(array: TSArrayType) {
        if visit(array: array) {
            visitImpl(type: array.element)
        }
        visitEnd(array: array)
    }

    public func visitImpl(dictionary: TSDictionaryType) {
        if visit(dictionary: dictionary) {
            visitImpl(type: dictionary.element)
        }
        visitEnd(dictionary: dictionary)
    }

    public func visitImpl(named: TSNamedType) {
        if visit(named: named) {
            visitImpl(genericArguments: named.genericArguments)
        }
        visitEnd(named: named)
    }

    public func visitImpl(nested: TSNestedType) {
        if visit(nested: nested) {
            visitImpl(type: nested.type)
        }
        visitEnd(nested: nested)
    }

    public func visitImpl(record: TSRecordType) {
        if visit(record: record) {
            for field in record.fields {
                visitImpl(recordField: field)
            }
        }
        visitEnd(record: record)
    }

    public func visitImpl(recordField: TSRecordType.Field) {
        if visit(recordField: recordField) {
            visitImpl(type: recordField.type)
        }
        visitEnd(recordField: recordField)
    }

    public func visitImpl(union: TSUnionType) {
        if visit(union: union) {
            for item in union.items {
                visitImpl(type: item)
            }
        }
        visitEnd(union: union)
    }

    public func visitImpl(functionArgument: TSFunctionArgument) {
        if visit(functionArgument: functionArgument) {
            visitImpl(expr: functionArgument.expr)
        }
        visitEnd(functionArgument: functionArgument)
    }

    public func visitImpl(functionArguments: [TSFunctionArgument]) {
        if visit(functionArguments: functionArguments) {
            for item in functionArguments {
                visitImpl(functionArgument: item)
            }
        }
        visitEnd(functionArguments: functionArguments)
    }

    public func visitImpl(functionParameter: TSFunctionParameter) {
        if visit(functionParameter: functionParameter) {
            if let type = functionParameter.type {
                visitImpl(type: type)
            }
        }
        visitEnd(functionParameter: functionParameter)
    }

    public func visitImpl(functionParameters: [TSFunctionParameter]) {
        if visit(functionParameters: functionParameters) {
            for item in functionParameters {
                visitImpl(functionParameter: item)
            }
        }
        visitEnd(functionParameters: functionParameters)
    }

    public func visitImpl(genericArgument: TSGenericArgument) {
        if visit(genericArgument: genericArgument) {
            visitImpl(type: genericArgument.type)
        }
        visitEnd(genericArgument: genericArgument)
    }

    public func visitImpl(genericArguments: [TSGenericArgument]) {
        if visit(genericArguments: genericArguments) {
            for item in genericArguments {
                visitImpl(genericArgument: item)
            }
        }
        visitEnd(genericArguments: genericArguments)
    }

    public func visitImpl(genericParameter: TSGenericParameter) {
        if visit(genericParameter: genericParameter) {
            visitImpl(type: genericParameter.type)
        }
        visitEnd(genericParameter: genericParameter)
    }

    public func visitImpl(genericParameters: [TSGenericParameter]) {
        if visit(genericParameters: genericParameters) {
            for item in genericParameters {
                visitImpl(genericParameter: item)
            }
        }
        visitEnd(genericParameters: genericParameters)
    }

    public func visitImpl(objectField: TSObjectField) {
        if visit(objectField: objectField) {
            visitImpl(expr: objectField.name)
            visitImpl(expr: objectField.value)
        }
        visitEnd(objectField: objectField)
    }

    public func visitImpl(objectFields: [TSObjectField]) {
        if visit(objectFields: objectFields) {
            for item in objectFields {
                visitImpl(objectField: item)
            }
        }
        visitEnd(objectFields: objectFields)
    }

    // MARK: default impl for user API

    public func visit(code: TSCode) -> Bool { true }
    public func visitEnd(code: TSCode) {}
    public func visit(item: TSBlockItem) -> Bool { true }
    public func visitEnd(item: TSBlockItem) {}
    public func visit(items: [TSBlockItem]) -> Bool { true }
    public func visitEnd(items: [TSBlockItem]) {}
    public func visit(function: TSFunctionDecl) -> Bool { true }
    public func visitEnd(function: TSFunctionDecl) {}
    public func visit(import: TSImportDecl) {}
    public func visit(namespace: TSNamespaceDecl) -> Bool { true }
    public func visitEnd(namespace: TSNamespaceDecl) {}
    public func visit(type: TSTypeDecl) -> Bool { true }
    public func visitEnd(type: TSTypeDecl) {}
    public func visit(`var`: TSVarDecl) -> Bool { true }
    public func visitEnd(`var`: TSVarDecl) {}
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
    public func visit(closure: TSClosureExpr) -> Bool { true }
    public func visitEnd(closure: TSClosureExpr) {}
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
    public func visit(recordField: TSRecordType.Field) -> Bool { true }
    public func visitEnd(recordField: TSRecordType.Field) {}
    public func visit(stringLiteral: TSStringLiteralType) {}
    public func visit(union: TSUnionType) -> Bool { true }
    public func visitEnd(union: TSUnionType) {}
    public func visit(functionArgument: TSFunctionArgument) -> Bool { true }
    public func visitEnd(functionArgument: TSFunctionArgument) {}
    public func visit(functionArguments: [TSFunctionArgument]) -> Bool { true }
    public func visitEnd(functionArguments: [TSFunctionArgument]) {}
    public func visit(functionParameter: TSFunctionParameter) -> Bool { true }
    public func visitEnd(functionParameter: TSFunctionParameter) {}
    public func visit(functionParameters: [TSFunctionParameter]) -> Bool { true }
    public func visitEnd(functionParameters: [TSFunctionParameter]) {}
    public func visit(genericParameter: TSGenericParameter) -> Bool { true }
    public func visitEnd(genericParameter: TSGenericParameter) {}
    public func visit(genericParameters: [TSGenericParameter]) -> Bool { true }
    public func visitEnd(genericParameters: [TSGenericParameter]) {}
    public func visit(genericArgument: TSGenericArgument) -> Bool { true }
    public func visitEnd(genericArgument: TSGenericArgument) {}
    public func visit(genericArguments: [TSGenericArgument]) -> Bool { true }
    public func visitEnd(genericArguments: [TSGenericArgument]) {}
    public func visit(objectField: TSObjectField) -> Bool { true }
    public func visitEnd(objectField: TSObjectField) {}
    public func visit(objectFields: [TSObjectField]) -> Bool { true }
    public func visitEnd(objectFields: [TSObjectField]) {}
}
