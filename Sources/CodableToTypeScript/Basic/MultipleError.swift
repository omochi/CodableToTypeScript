struct MultipleError: Error, CustomStringConvertible {
    var errors: [any Error]

    var description: String {
        errors.map { "\($0)" }
            .joined(separator: "\n")
    }

    class ErrorCollector {
        fileprivate var errors: [any Error] = []

        func callAsFunction<T>(
            _ context: String? = nil,
            _ run: (() throws -> T)
        ) -> T? {
            do {
                return try run()
            } catch {
                if let context {
                    if let multiple = error as? MultipleError {
                        errors.append(contentsOf: multiple.errors.map { ContextError(context, error: $0) })
                    } else {
                        errors.append(ContextError(context, error: error))
                    }
                } else {
                    if let multiple = error as? MultipleError {
                        errors.append(contentsOf: multiple.errors)
                    } else {
                        errors.append(error)
                    }
                }
            }
            return nil
        }
    }

    static func collect<T>(
        _ run: (_ `do`: ErrorCollector) -> T
    ) throws -> T {
        let collector = ErrorCollector()
        let result = run(collector)
        if !collector.errors.isEmpty {
            throw MultipleError(errors: collector.errors)
        }
        return result
    }
}
