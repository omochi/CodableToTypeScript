enum TSKeyword: String, Sendable & Hashable {
    case `break`
    case `case`
    case `catch`
    case `class`
    case const
    case `continue`
    case debugger
    case `default`
    case delete
    case `do`
    case `else`
    case export
    case extends
    case `false`
    case finally
    case `for`
    case function
    case `if`
    case `import`
    case `in`
    case instanceof
    case new
    case null
    case `return`
    case `super`
    case `switch`
    case this
    case `throw`
    case `true`
    case `try`
    case typeof
    case `var`
    case void
    case `while`
    case with
    case `let`
    case `static`
    case yield
    case await

    static func escaped(_ identifier: String) -> String {
        if TSKeyword(rawValue: identifier) != nil {
            return "_\(identifier)"
        } else {
            return identifier
        }
    }
}
