import SwiftTypeReader

public protocol TypeConverter {
    func hasJSONType() throws -> Bool
}
