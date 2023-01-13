import WasmCallableKit

extension WasmCallableKit {
    static func install() {
        
        registerClassMetadata(meta: [
            buildGeneratorMetadata(),
        ])
    }
}