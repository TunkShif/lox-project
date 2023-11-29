import * as monaco from "monaco-editor"
import { ParentComponent, createContext, useContext } from "solid-js"
import { SetStoreFunction, createStore } from "solid-js/store"

export type Store = {
  editor: monaco.editor.IStandaloneCodeEditor | null
  output: string
}

const StoreContext = createContext<[Store, SetStoreFunction<Store>]>()

export const StoreProvider: ParentComponent = (props) => {
  const store = createStore<Store>({ output: "==> ", editor: null })
  return <StoreContext.Provider value={store} children={props.children} />
}

export const useStore = () => useContext(StoreContext)!
