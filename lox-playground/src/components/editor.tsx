import { useStore } from "@/store"
import * as monaco from "monaco-editor"
import { onMount } from "solid-js"
import { Box } from "styled-system/jsx"

const defaultSource = `
let outer = "first";
{
  let captured = outer;
  let inner = captured + " and second";
  let outer = "redefined";
  {
  let nested = "another layer";
  }
}
let sum = 1 + 2 + 3;
undefined;
`.trim()

export const Editor = () => {
  let ref: HTMLDivElement

  const [, setStore] = useStore()

  onMount(() => {
    const instance = monaco.editor.create(ref, {
      value: defaultSource,
      language: "javascript",
      automaticLayout: true
    })
    setStore("editor", instance)
  })

  return <Box ref={ref!} w="full" h="full" />
}
