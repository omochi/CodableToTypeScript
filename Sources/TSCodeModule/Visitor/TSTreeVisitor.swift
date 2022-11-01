public protocol TSTreeVisitor {
    func visit(code: TSCode) -> Bool
    func visitEnd(code: TSCode)
    func visit(item: TSBlockItem) -> Bool
    func visitEnd(item: TSBlockItem)
    func visit(items: [TSBlockItem]) -> Bool
    func visitEnd(items: [TSBlockItem])
    func visit(class: TSClassDecl) -> Bool
    func visitEnd(class: TSClassDecl)
    func visit(function: TSFunctionDecl) -> Bool
    func visitEnd(function: TSFunctionDecl)
    func visit(import: TSImportDecl) -> Bool
    func visitEnd(import: TSImportDecl)
    func visit(interface: TSInterfaceDecl) -> Bool
    func visitEnd(interface: TSInterfaceDecl)
    func visit(method: TSMethodDecl) -> Bool
    func visitEnd(method: TSMethodDecl)
    func visit(namespace: TSNamespaceDecl) -> Bool
    func visitEnd(namespace: TSNamespaceDecl)
    func visit(type: TSTypeDecl) -> Bool
    func visitEnd(type: TSTypeDecl)
    func visit(`var`: TSVarDecl) -> Bool
    func visitEnd(`var`: TSVarDecl)
    func visit(custom: TSCustomDecl) -> Bool
    func visitEnd(custom: TSCustomDecl)
    func visit(block: TSBlockStmt) -> Bool
    func visitEnd(block: TSBlockStmt)
    func visit(expr: TSExprStmt) -> Bool
    func visitEnd(expr: TSExprStmt)
    func visit(for: TSForStmt) -> Bool
    func visitEnd(for: TSForStmt)
    func visit(if: TSIfStmt) -> Bool
    func visitEnd(if: TSIfStmt)
    func visit(return: TSReturnStmt) -> Bool
    func visitEnd(return: TSReturnStmt)
    func visit(throw: TSThrowStmt) -> Bool
    func visitEnd(throw: TSThrowStmt)
    func visit(custom: TSCustomStmt) -> Bool
    func visitEnd(custom: TSCustomStmt)
    func visit(call: TSCallExpr) -> Bool
    func visitEnd(call: TSCallExpr)
    func visit(closure: TSClosureExpr) -> Bool
    func visitEnd(closure: TSClosureExpr)
    func visit(identifier: TSIdentifierExpr) -> Bool
    func visitEnd(identifier: TSIdentifierExpr)
    func visit(infixOperator: TSInfixOperatorExpr) -> Bool
    func visitEnd(infixOperator: TSInfixOperatorExpr)
    func visit(memberAccess: TSMemberAccessExpr) -> Bool
    func visitEnd(memberAccess: TSMemberAccessExpr)
    func visit(new: TSNewExpr) -> Bool
    func visitEnd(new: TSNewExpr)
    func visit(numberLiteral: TSNumberLiteralExpr) -> Bool
    func visitEnd(numberLiteral: TSNumberLiteralExpr)
    func visit(object: TSObjectExpr) -> Bool
    func visitEnd(object: TSObjectExpr)
    func visit(prefixOperator: TSPrefixOperatorExpr) -> Bool
    func visitEnd(prefixOperator: TSPrefixOperatorExpr)
    func visit(stringLiteral: TSStringLiteralExpr) -> Bool
    func visitEnd(stringLiteral: TSStringLiteralExpr)
    func visit(subscript: TSSubscriptExpr) -> Bool
    func visitEnd(subscript: TSSubscriptExpr)
    func visit(type: TSTypeExpr) -> Bool
    func visitEnd(type: TSTypeExpr)
    func visit(custom: TSCustomExpr) -> Bool
    func visitEnd(custom: TSCustomExpr)
    func visit(array: TSArrayType) -> Bool
    func visitEnd(array: TSArrayType)
    func visit(dictionary: TSDictionaryType) -> Bool
    func visitEnd(dictionary: TSDictionaryType)
    func visit(function: TSFunctionType) -> Bool
    func visitEnd(function: TSFunctionType)
    func visit(named: TSNamedType) -> Bool
    func visitEnd(named: TSNamedType)
    func visit(nested: TSNestedType) -> Bool
    func visitEnd(nested: TSNestedType)
    func visit(record: TSRecordType) -> Bool
    func visitEnd(record: TSRecordType)
    func visit(recordField: TSRecordType.Field) -> Bool
    func visitEnd(recordField: TSRecordType.Field)
    func visit(stringLiteral: TSStringLiteralType) -> Bool
    func visitEnd(stringLiteral: TSStringLiteralType)
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

    public func visitImpl(items: [TSBlockItem]?) {
        guard let items = items else { return }

        if visit(items: items) {
            for item in items {
                visitImpl(item: item)
            }
        }
        visitEnd(items: items)
    }

    public func visitImpl(decl: TSDecl) {
        switch decl {
        case .class(let d): visitImpl(class: d)
        case .function(let d): visitImpl(function: d)
        case .import(let d): visitImpl(import: d)
        case .interface(let d): visitImpl(interface: d)
        case .method(let d): visitImpl(method: d)
        case .namespace(let d): visitImpl(namespace: d)
        case .type(let d): visitImpl(type: d)
        case .var(let d): visitImpl(var: d)
        case .custom(let d): visitImpl(custom: d)
        }
    }

    public func visitImpl(stmt: TSStmt) {
        switch stmt {
        case .block(let s): visitImpl(block: s)
        case .expr(let s): visitImpl(expr: s)
        case .for(let s): visitImpl(for: s)
        case .if(let s): visitImpl(if: s)
        case .return(let s): visitImpl(return: s)
        case .throw(let s): visitImpl(throw: s)
        case .custom(let s): visitImpl(custom: s)
        }
    }

    public func visitImpl(expr: TSExpr) {
        switch expr {
        case .call(let e): visitImpl(call: e)
        case .closure(let e): visitImpl(closure: e)
        case .identifier(let e): visitImpl(identifier: e)
        case .infixOperator(let e): visitImpl(infixOperator: e)
        case .memberAccess(let e): visitImpl(memberAccess: e)
        case .new(let e): visitImpl(new: e)
        case .numberLiteral(let e): visitImpl(numberLiteral: e)
        case .object(let e): visitImpl(object: e)
        case .prefixOperator(let e): visitImpl(prefixOperator: e)
        case .stringLiteral(let e): visitImpl(stringLiteral: e)
        case .subscript(let e): visitImpl(subscript: e)
        case .type(let e): visitImpl(type: e)
        case .custom(let e): visitImpl(custom: e)
        }
    }

    public func visitImpl(type: TSType?) {
        guard let type else { return }
        switch type {
        case .array(let t): visitImpl(array: t)
        case .dictionary(let t): visitImpl(dictionary: t)
        case .function(let t): visitImpl(function: t)
        case .named(let t): visitImpl(named: t)
        case .nested(let t): visitImpl(nested: t)
        case .record(let t): visitImpl(record: t)
        case .stringLiteral(let t): visitImpl(stringLiteral: t)
        case .union(let t): visitImpl(union: t)
        }
    }

    public func visitImpl(types: [TSType]?) {
        guard let types else { return }
        for type in types {
            visitImpl(type: type)
        }
    }

    // MARK: single impls

    public func visitImpl(class: TSClassDecl) {
        if visit(class: `class`) {
            visitImpl(genericParameters: `class`.genericParameters)
            visitImpl(type: `class`.extends)
            visitImpl(types: `class`.implements)
            visitImpl(items: `class`.items)
        }
        visitEnd(class: `class`)
    }

    public func visitImpl(function: TSFunctionDecl) {
        if visit(function: function) {
            visitImpl(genericParameters: function.genericParameters)
            visitImpl(functionParameters: function.parameters)
            visitImpl(items: function.items)
        }
        visitEnd(function: function)
    }

    public func visitImpl(import: TSImportDecl) {
        if visit(import: `import`) {}
        visitEnd(import: `import`)
    }

    public func visitImpl(interface: TSInterfaceDecl) {
        if visit(interface: interface) {
            visitImpl(genericParameters: interface.genericParameters)
            visitImpl(types: interface.extends)
            visitImpl(items: interface.decls.map { .decl($0) })
        }
        visitEnd(interface: interface)
    }

    public func visitImpl(method: TSMethodDecl) {
        if visit(method: method) {
            visitImpl(genericParameters: method.genericParameters)
            visitImpl(functionParameters: method.parameters)
            visitImpl(type: method.returnType)
            visitImpl(items: method.items)
        }
        visitEnd(method: method)
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

    public func visitImpl(custom: TSCustomDecl) {
        if visit(custom: custom) {}
        visitEnd(custom: custom)
    }

    public func visitImpl(block: TSBlockStmt) {
        if visit(block: block) {
            visitImpl(items: block.items)
        }
        visitEnd(block: block)
    }

    public func visitImpl(expr: TSExprStmt) {
        if visit(expr: expr) {
            visitImpl(expr: expr.expr)
        }
        visitEnd(expr: expr)
    }

    public func visitImpl(for: TSForStmt) {
        if visit(for: `for`) {
            visitImpl(expr: `for`.expr)
            visitImpl(stmt: `for`.body)
        }
        visitEnd(for: `for`)
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

    public func visitImpl(custom: TSCustomStmt) {
        if visit(custom: custom) {}
        visitEnd(custom: custom)
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
            visitImpl(type: closure.returnType)
            visitImpl(stmt: closure.body)
        }
        visitEnd(closure: closure)
    }

    public func visitImpl(identifier: TSIdentifierExpr) {
        if visit(identifier: identifier) {}
        visitEnd(identifier: identifier)
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

    public func visitImpl(numberLiteral: TSNumberLiteralExpr) {
        if visit(numberLiteral: numberLiteral) {}
        visitEnd(numberLiteral: numberLiteral)
    }

    public func visitImpl(object: TSObjectExpr) {
        if visit(object: object) {
            visitImpl(objectFields: object.fields)
        }
        visitEnd(object: object)
    }

    public func visitImpl(prefixOperator: TSPrefixOperatorExpr) {
        if visit(prefixOperator: prefixOperator) {
            visitImpl(expr: prefixOperator.expr)
        }
        visitEnd(prefixOperator: prefixOperator)
    }

    public func visitImpl(stringLiteral: TSStringLiteralExpr) {
        if visit(stringLiteral: stringLiteral) {}
        visitEnd(stringLiteral: stringLiteral)
    }

    public func visitImpl(subscript: TSSubscriptExpr) {
        if visit(subscript: `subscript`) {
            visitImpl(expr: `subscript`.base)
            visitImpl(expr: `subscript`.key)
        }
        visitEnd(subscript: `subscript`)
    }

    public func visitImpl(type: TSTypeExpr) {
        if visit(type: type) {
            visitImpl(type: type.type)
        }
        visitEnd(type: type)
    }

    public func visitImpl(custom: TSCustomExpr) {
        if visit(custom: custom) {}
        visitEnd(custom: custom)
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

    public func visitImpl(function: TSFunctionType) {
        if visit(function: function) {
            visitImpl(functionParameters: function.parameters)
            visitImpl(type: function.returnType)
        }
        visitEnd(function: function)
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

    public func visitImpl(stringLiteral: TSStringLiteralType) {
        if visit(stringLiteral: stringLiteral) { }
        visitEnd(stringLiteral: stringLiteral)
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
        if visit(genericParameter: genericParameter) {}
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
    public func visit(class: TSClassDecl) -> Bool { true }
    public func visitEnd(class: TSClassDecl) {}
    public func visit(function: TSFunctionDecl) -> Bool { true }
    public func visitEnd(function: TSFunctionDecl) {}
    public func visit(import: TSImportDecl) -> Bool { true }
    public func visitEnd(import: TSImportDecl) {}
    public func visit(interface: TSInterfaceDecl) -> Bool { true }
    public func visitEnd(interface: TSInterfaceDecl) {}
    public func visit(method: TSMethodDecl) -> Bool { true }
    public func visitEnd(method: TSMethodDecl) {}
    public func visit(namespace: TSNamespaceDecl) -> Bool { true }
    public func visitEnd(namespace: TSNamespaceDecl) {}
    public func visit(type: TSTypeDecl) -> Bool { true }
    public func visitEnd(type: TSTypeDecl) {}
    public func visit(`var`: TSVarDecl) -> Bool { true }
    public func visitEnd(`var`: TSVarDecl) {}
    public func visit(custom: TSCustomDecl) -> Bool { true }
    public func visitEnd(custom: TSCustomDecl) {}
    public func visit(block: TSBlockStmt) -> Bool { true }
    public func visitEnd(block: TSBlockStmt) {}
    public func visit(expr: TSExprStmt) -> Bool { true }
    public func visitEnd(expr: TSExprStmt) {}
    public func visit(if: TSIfStmt) -> Bool { true }
    public func visitEnd(if: TSIfStmt) {}
    public func visit(for: TSForStmt) -> Bool { true }
    public func visitEnd(for: TSForStmt) {}
    public func visit(return: TSReturnStmt) -> Bool { true }
    public func visitEnd(return: TSReturnStmt) {}
    public func visit(throw: TSThrowStmt) -> Bool { true }
    public func visitEnd(throw: TSThrowStmt) {}
    public func visit(custom: TSCustomStmt) -> Bool { true }
    public func visitEnd(custom: TSCustomStmt) {}
    public func visit(call: TSCallExpr) -> Bool { true }
    public func visitEnd(call: TSCallExpr) {}
    public func visit(closure: TSClosureExpr) -> Bool { true }
    public func visitEnd(closure: TSClosureExpr) {}
    public func visit(identifier: TSIdentifierExpr) -> Bool { true }
    public func visitEnd(identifier: TSIdentifierExpr) {}
    public func visit(infixOperator: TSInfixOperatorExpr) -> Bool { true }
    public func visitEnd(infixOperator: TSInfixOperatorExpr) {}
    public func visit(memberAccess: TSMemberAccessExpr) -> Bool { true }
    public func visitEnd(memberAccess: TSMemberAccessExpr) {}
    public func visit(new: TSNewExpr) -> Bool { true }
    public func visitEnd(new: TSNewExpr) {}
    public func visit(numberLiteral: TSNumberLiteralExpr) -> Bool { true }
    public func visitEnd(numberLiteral: TSNumberLiteralExpr) {}
    public func visit(object: TSObjectExpr) -> Bool { true }
    public func visitEnd(object: TSObjectExpr) {}
    public func visit(stringLiteral: TSStringLiteralExpr) -> Bool { true }
    public func visitEnd(stringLiteral: TSStringLiteralExpr) {}
    public func visit(custom: TSCustomExpr) -> Bool { true }
    public func visitEnd(custom: TSCustomExpr) {}
    public func visit(array: TSArrayType) -> Bool { true }
    public func visitEnd(array: TSArrayType) {}
    public func visit(dictionary: TSDictionaryType) -> Bool { true }
    public func visitEnd(dictionary: TSDictionaryType) {}
    public func visit(function: TSFunctionType) -> Bool { true }
    public func visitEnd(function: TSFunctionType) {}
    public func visit(named: TSNamedType) -> Bool { true }
    public func visitEnd(named: TSNamedType) {}
    public func visit(nested: TSNestedType) -> Bool { true }
    public func visitEnd(nested: TSNestedType) {}
    public func visit(record: TSRecordType) -> Bool { true }
    public func visitEnd(record: TSRecordType) {}
    public func visit(recordField: TSRecordType.Field) -> Bool { true }
    public func visitEnd(recordField: TSRecordType.Field) {}
    public func visit(prefixOperator: TSPrefixOperatorExpr) -> Bool { true }
    public func visitEnd(prefixOperator: TSPrefixOperatorExpr) {}
    public func visit(stringLiteral: TSStringLiteralType) -> Bool { true }
    public func visitEnd(stringLiteral: TSStringLiteralType) {}
    public func visit(subscript: TSSubscriptExpr) -> Bool { true }
    public func visitEnd(subscript: TSSubscriptExpr) {}
    public func visit(type: TSTypeExpr) -> Bool { true }
    public func visitEnd(type: TSTypeExpr) {}
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