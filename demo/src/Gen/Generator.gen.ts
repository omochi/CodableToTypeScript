import { SwiftRuntime, globalRuntime } from "./SwiftRuntime.gen.js";

export class Generator {
    #runtime: SwiftRuntime;
    #id: number;

    constructor(runtime?: SwiftRuntime) {
        this.#runtime = runtime ?? globalRuntime;
        this.#id = this.#runtime.classInit(0, 0, {});
        this.#runtime.autorelease(this, this.#id);
    }

    tsTypes(swiftSource: string): string {
        return this.#runtime.classSend(this.#id, 0, {
            _0: swiftSource
        }) as string;
    }

    commonLib(): string {
        return this.#runtime.classSend(this.#id, 1, {}) as string;
    }
}
