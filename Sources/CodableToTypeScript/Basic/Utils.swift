import SwiftTypeReader

extension DefaultStringInterpolation {
    mutating func appendInterpolation<S: Sequence>(
        lines: S,
        _ f: (S.Element) -> String
    ) {
        let str = lines.map { f($0) }.joined(separator: "\n")
        self.appendInterpolation(str)
    }
}

enum Utils {
    static func pascalCase(_ str: String) -> String {
        if str.isEmpty { return str }

        let i0 = str.startIndex
        var head = String(str[i0])
        head = head.uppercased()

        let i1 = str.index(after: i0)
        let tail = str[i1...]

        return head + tail
    }

    static func label(of assoc: AssociatedValue, _ index: Int) -> String {
        if let name = assoc.name {
            return name
        } else {
            return "_\(index)"
        }
    }

    static func unwrapOptional(_ type: Type, limit: Int?) -> (type: Type, isWrapped: Bool) {
        var isWrapped = false
        var type = type
        var i = 0
        while let st = type.struct,
           st.name == "Optional",
           st.genericsArguments.count > 0
        {
            if let limit = limit,
               i >= limit
            {
                break
            }

            type = st.genericsArguments[0]
            isWrapped = true
            i += 1
        }
        return (type: type, isWrapped: isWrapped)
    }

}
