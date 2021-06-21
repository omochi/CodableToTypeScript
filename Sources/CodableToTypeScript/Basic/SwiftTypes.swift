import SwiftTypeReader

enum SwiftTypes {
    static func isObjectCodingEnum(_ type: EnumType) throws -> Bool {
        let ihs = try type.inheritedTypes().map { $0.name }

        let isCodable = ihs.contains("Codable") ||
            ihs.contains("Encodable") ||
            ihs.contains("Decodable")
        guard isCodable else { return false }

        let isRawRepresentable = ihs.contains("String") ||
            ihs.contains("RawRepresentable")
        if isRawRepresentable { return false }

        return true
    }
}
