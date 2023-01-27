struct ContextError: Error, CustomStringConvertible {
    var contexts: [String]
    var error: any Error

    init(_ context: String, error: any Error) {
        if let error = error as? ContextError {
            self.contexts = [context] + error.contexts
            self.error = error.error
        } else {
            self.contexts = [context]
            self.error = error
        }
    }

    var description: String {
        "\(contexts.joined(separator: "."))\t: \(error)"
    }
}
