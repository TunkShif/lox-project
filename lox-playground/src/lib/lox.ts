export type Imports = {
  env: {
    consoleWrite(ptr: number, len: number): void
  }
}

export type Exports = {
  memory: { buffer: ArrayBuffer }
  initVM(): void
  deinitVM(): void
  interpret(ptr: number, len: number): void
  alloc(size: number): number
  free(ptr: number, len: number): void
}

let exports: Exports
const encoder = new TextEncoder()
const decoder = new TextDecoder()

const output = { buffer: "" }

const imports = {
  env: {
    consoleWrite(ptr: number, len: number) {
      const decoded = decoder.decode(new Uint8Array(exports.memory.buffer, ptr, len))
      output.buffer += decoded
    }
  }
} satisfies Imports

export const Lox = {
  async init() {
    const wasm = await WebAssembly.instantiateStreaming(fetch("/lox-zg.wasm"), imports)
    exports = wasm.instance.exports as unknown as Exports
    exports.initVM()
    return this
  },
  interpret(source: string) {
    const encoded = encoder.encode(source)

    const len = encoded.length
    const ptr = exports.alloc(len)

    if (ptr === 0) throw new Error("Allocation failed.")
    const buffer = new Uint8Array(exports.memory.buffer)
    for (let i = 0; i < len; i++) {
      buffer[ptr + i] = encoded[i]
    }

    output.buffer = ""
    exports.interpret(ptr, len)
    exports.free(ptr, len)

    return output.buffer
  },
  destroy() {
    exports.deinitVM()
  }
}
