import { Button } from "@/components/ui/button"
import { GitHubIcon, ZapIcon } from "@/components/ui/icons"
import { Lox } from "@/lib/lox"
import { useStore } from "@/store"
import { css } from "styled-system/css"
import { Flex, styled } from "styled-system/jsx"

export const Header = () => {
  const [store, setStore] = useStore()

  const handleRun = () => {
    const editor = store.editor
    if (editor) {
      const result = Lox.interpret(editor.getValue())
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
        <Button asChild>
          <a href="https://github.com/TunkShif/lox-project" target="_blank">
            <GitHubIcon class={css({ display: "inline-block", w: "5", h: "5" })} />
            GitHub
          </a>
        </Button>
      </Flex>
    </styled.header>
  )
}
