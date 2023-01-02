import Foundation

extension URL {
    func replacingPathExtension(_ ext: String) -> URL {
        let dir = deletingLastPathComponent()
        var base = lastPathComponent
        let stem = (base as NSString).deletingPathExtension
        base = stem
        if !ext.isEmpty {
            base += "." + ext
        }
        return dir.appendingPathComponent(base)
    }
}
