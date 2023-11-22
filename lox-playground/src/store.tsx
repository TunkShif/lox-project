import * as monaco from "monaco-editor"
import { createResource } from "solid-js"
import { createStore } from "solid-js/store"
import { Lox } from "./lib/lox"

export type State = {
  editor: monaco.editor.IStandaloneCodeEditor | null
  output: string
}

export const [lox] = createResource(() => Lox.init())

export const [store, setStore] = createStore<State>({ output: "==> ", editor: null })
