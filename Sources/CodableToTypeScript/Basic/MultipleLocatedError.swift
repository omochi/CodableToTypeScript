struct MultipleLocatedError: Error, CustomStringConvertible {
    struct Entry: CustomStringConvertible {
        var location: [String]
        var error: any Error
        var description: String {
            "\(location.joined(separator: ".")): \(error)"
        }
    }
    var entries: [Entry]

    var description: String {
        entries.map(\.description)
            .joined(separator: "\n")
    }

    class ErrorCollector {
        fileprivate var entries: [MultipleLocatedError.Entry] = []

        func callAsFunction<T>(
            at: String? = nil,
            _ run: (() throws -> T)
        ) -> T? {
            do {
                return try run()
            } catch {
                var newEntries: [Entry]
                if let multiple = error as? MultipleLocatedError {
                    newEntries = multiple.entries
                } else {
                    newEntries = [.init(location: [], error: error)]
                }

                if let at {
                    for i in newEntries.indices {
                        newEntries[i].location.insert(at, at: 0)
                    }
                }

                entries.append(contentsOf: newEntries)
                return nil
            }
        }
    }
}

func withErrorCollector<T>(_ run: (_ `collect`: MultipleLocatedError.ErrorCollector) -> T) throws -> T {
    let collector = MultipleLocatedError.ErrorCollector()
    let result = run(collector)
    if !collector.entries.isEmpty {
        throw MultipleLocatedError(entries: collector.entries)
    }
    return result
}
