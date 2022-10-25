import SwiftTypeReader
import TSCodeModule

struct NamespaceBuilder {
    var elements: [LocationElement]

    init(location: Location) {
        self.elements = location.elements
    }

    func build(decls: [TSDecl]) -> [TSDecl] {
        return build(decls: decls, index: 0)
    }

    private func build(decls: [TSDecl], index: Int) -> [TSDecl] {
        guard index < elements.count else {
            return decls
        }
        let element = elements[index]
        switch element {
        case .type(name: let name):
            let decls = build(decls: decls, index: index + 1)
            return decls.map { (decl) in
                let ns = TSNamespaceDecl(
                    name: name,
                    decls: [decl]
                )
                return .namespaceDecl(ns)
            }
        default:
            return build(decls: decls, index: index + 1)
        }
    }
}
