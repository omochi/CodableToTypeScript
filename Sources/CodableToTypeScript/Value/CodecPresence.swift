public enum CodecPresence: Int, Comparable {
    case identity       = 0
    case conditional    = 1
    case required       = 2

    public static func < (lhs: CodecPresence, rhs: CodecPresence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
