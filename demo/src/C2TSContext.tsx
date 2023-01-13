import React, { PropsWithChildren, useContext, useEffect, useState } from "react";
import { WASI } from "@wasmer/wasi";
import wasiBindings from "@wasmer/wasi/lib/bindings/browser";
import { WasmFs } from "@wasmer/wasmfs";
import { SwiftRuntime } from "./Gen/SwiftRuntime.gen";

const wasmPath = "./C2TS.wasm";

const startWasiTask = async () => {
  const wasmFs = new WasmFs();
  const rawWriteSync = wasmFs.fs.writeSync;
  // @ts-ignore
  wasmFs.fs.writeSync = (fd, buffer, offset, length, position): number => {
    const text = new TextDecoder("utf-8").decode(buffer);
    if (text !== "\n") {
      switch (fd) {
        case 1:
          console.log(text);
          break;
        case 2:
          console.error(text);
          break;
      }
    }
    return rawWriteSync(fd, buffer, offset, length, position);
  };
  
  let wasi = new WASI({
    args: [],
    env: {},
    bindings: {
      ...wasiBindings,
      fs: wasmFs.fs
    }
  });

  const swift = new SwiftRuntime();
  const { instance } = await WebAssembly.instantiateStreaming(fetch(wasmPath), {
    wasi_snapshot_preview1: wasi.wasiImport,
    ...swift.callableKitImports,
  });
  swift.setInstance(instance);
  const { memory, _initialize, main } = instance.exports as any;
  wasi.setMemory(memory);
  _initialize();
  main();
  
  return swift;
};

const C2TSContext = React.createContext<object | null>(null);

export const C2TSProvider: React.FC<PropsWithChildren<{}>> = (props) => {
  const [exports, setExports] = useState<object | null>();
  useEffect(() => {
    startWasiTask().then(setExports);
  }, []);

  if (exports == null) {
    return <>{props.children}</>;
  }

  return <C2TSContext.Provider value={exports}>
    {props.children}
  </C2TSContext.Provider>;
};

export const useC2TS = (): { isReady: boolean } => {
  const context = useContext(C2TSContext);
  return {
    isReady: context != null,
  }
}
