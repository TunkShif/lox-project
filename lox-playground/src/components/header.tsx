import { Button } from "@/components/ui/button"
import { lox, setStore, store } from "@/store"
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
      <styled.h1 fontSize="lg" fontWeight="semibold">
        Lox Playground
      </styled.h1>
      <Flex gap="2">
        <Button onClick={handleRun}>Run</Button>
      </Flex>
    </styled.header>
  )
}
