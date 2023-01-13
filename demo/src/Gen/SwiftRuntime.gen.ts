class Memory {
  readonly rawMemory: WebAssembly.Memory;
  constructor(exports: WebAssembly.Exports) {
    this.rawMemory = exports.memory as WebAssembly.Memory;
  }
  bytes(): Uint8Array {
    return new Uint8Array(this.rawMemory.buffer);
  }
  writeBytes(ptr: number, bytes: Uint8Array): void {
    this.bytes().set(bytes, ptr);
  }
}

type WasmCallableKitExported = {
  ck_send: (functionID: number, argumentBufferLength: number) => number;
  ck_class_init: (classID: number, initilizerID: number, argumentBufferLength: number) => number;
  ck_class_send: (instanceID: number, functionID: number, argumentBufferLength: number) => number;
  ck_class_free: (instanceID: number) => void;
};

export var globalRuntime: SwiftRuntime;

export class SwiftRuntime {
  #_instance: WebAssembly.Instance | null = null;
  #_memory: Memory | null = null;

  #nextArgument: Uint8Array | null = null;
  #nextReturn: string | null = null;

  #textDecoder = new TextDecoder("utf-8");
  #textEncoder = new TextEncoder();

  #pool = new FinalizationRegistry((instanceID: number) => {
    this.#callableKitExports.ck_class_free(instanceID);
  });

  constructor() {
    globalRuntime = this;
  }

  setInstance(instance: WebAssembly.Instance) {
    this.#_instance = instance;
  }

  get #instance(): WebAssembly.Instance {
    if (!this.#_instance)
      throw new Error("WebAssembly instance is not set yet");
    return this.#_instance;
  }

  get #memory(): Memory {
    if (!this.#_memory) {
      this.#_memory = new Memory(this.#instance.exports);
    }
    return this.#_memory;
  }

  get #callableKitExports(): WasmCallableKitExported {
    return this.#instance.exports as WasmCallableKitExported;
  }

  get callableKitImports(): WebAssembly.Imports {
    const callable_kit = {
      receive_arg: (buffer: number) => {
        this.#memory.writeBytes(buffer, this.#nextArgument!!);
        this.#nextArgument = null;
      },
      write_ret: (buffer: number, length: number) => {
        const bytes = this.#memory.bytes().subarray(buffer, buffer + length);
        this.#nextReturn = this.#textDecoder.decode(bytes);
      },
    };
    return { callable_kit };
  }

  #pushArg(argument: unknown): number {
    const argJsonString = JSON.stringify(argument) + '\0';
    const argBytes = this.#textEncoder.encode(argJsonString);
    this.#nextArgument = argBytes;
    return argBytes.length;
  }

  #popReturn(): string | null {
    const returnValue = this.#nextReturn!!;
    this.#nextReturn = null;
    return returnValue;
  }

  send(functionID: number, argument: unknown): unknown {
    const argLen = this.#pushArg(argument);
    const out = this.#callableKitExports.ck_send(functionID, argLen);
    const returnValue = this.#popReturn()!!;
    switch (out) {
      case 0:
        if (returnValue === "") return;
        return JSON.parse(returnValue);
      case -1:
        throw new Error(returnValue);
      default:
        throw new Error("unexpected");
    }
  }

  classInit(classID: number, initializerID: number, argument: unknown): number {
    const argLen = this.#pushArg(argument);
    const out = this.#callableKitExports.ck_class_init(classID, initializerID, argLen);
    switch (out) {
      case -1:
        throw new Error(this.#popReturn()!!);
      default:
        return out;
    }
  }

  classSend(instanceID: number, functionID: number, argument: unknown): unknown {
    const argLen = this.#pushArg(argument);
    const out = this.#callableKitExports.ck_class_send(instanceID, functionID, argLen);
    const returnValue = this.#popReturn()!!;
    switch (out) {
      case 0:
        if (returnValue === "") return;
        return JSON.parse(returnValue);
      case -1:
        throw new Error(returnValue);
      default:
        throw new Error("unexpected");
    }
  }

  autorelease(obj: object, instanceID: number): void {
    this.#pool.register(obj, instanceID);
  }
}
