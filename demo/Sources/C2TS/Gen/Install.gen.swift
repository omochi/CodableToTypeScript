import WasmCallableKit

extension WasmCallableKit {
    static func install() {
        
        registerClassMetadata(meta: [
            buildC2TSMetadata(),
        ])
    }
}