import { Button } from "@/components/ui/button"
import { ZapIcon } from "@/components/ui/icons"
import { lox, setStore, store } from "@/store"
import { css } from "styled-system/css"
import { Flex, styled } from "styled-system/jsx"

export const Header = () => {
  const handleRun = () => {
    const interpreter = lox()
    const editor = store.editor
    if (editor && interpreter) {
      const result = interpreter.interpret(editor.getValue())
      setStore("output", result)
    }
  }

  const handleClear = () => {
    setStore("output", "")
  }

  return (
    <styled.header
      h="16"
      w="full"
      px="8"
      py="4"
      display="flex"
      justifyContent="space-between"
      alignItems="center"
      borderBottomWidth="1px"
      borderColor="border.default"
    >
      <styled.h1
        display="flex"
        justifyContent="center"
        alignItems="center"
        fontSize="lg"
        fontWeight="semibold"
      >
        <ZapIcon
          class={css({ display: "inline-block", w: "5", h: "5", mr: "2", color: "accent.9" })}
        />
        Lox Playground
      </styled.h1>
      <Flex gap="2">
        <Button onClick={handleRun}>Run</Button>
        <Button variant="outline" onClick={handleClear}>
          Clear
        </Button>
      </Flex>
    </styled.header>
  )
}
