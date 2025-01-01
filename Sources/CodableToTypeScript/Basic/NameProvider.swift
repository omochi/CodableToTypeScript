import TypeScriptAST

struct NameProvider {
    init() {}

    private var used: Set<String> = []

    mutating func register(signature: TSFunctionDecl) {
        for param in signature.params {
            register(name: param.name)
        }
    }

    mutating func register(name: String) {
        used.insert(name)
    }

    mutating func provide(base: String) -> String {
        if let name = provideIfUnused(name: base) {
            return name
        }

        var i = 2
        while true {
            let cand = "\(base)\(i)"
            if let name = provideIfUnused(name: cand) {
                return name
            }
            i += 1
        }
    }

    mutating func provideIfUnused(name: String) -> String? {
        if used.contains(name) {
            return nil
        }
        used.insert(name)
        return name
    }
}
