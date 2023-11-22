import { Editor } from "@/components/editor"
import { Header } from "@/components/header"
import { Output } from "@/components/output"
import { Box, styled } from "styled-system/jsx"

export const App = () => {
  return (
    <Box w="full" h="screen" fontFamily="sans">
      <Header />

      <styled.main w="full" h="full" display="flex" gap="8">
        <Box w="full" h="full" flex="2" borderRightWidth="1px" borderColor="border.default">
          <Editor />
        </Box>

        <Box w="full" h="full" flex="1" py="4">
          <Output />
        </Box>
      </styled.main>
    </Box>
  )
}
