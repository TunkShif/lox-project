import { Editor } from "@/components/editor"
import { Header } from "@/components/header"
import { Output } from "@/components/output"
import { Box, Flex, styled } from "styled-system/jsx"

export const App = () => {
  return (
    <Flex flexDirection="column" w="full" h="screen" fontFamily="sans">
      <Header />

      <styled.main w="full" display="flex" flex="1" overflow="hidden" gap="8">
        <Box w="full" h="full" flex="2" borderRightWidth="1px" borderColor="border.default">
          <Editor />
        </Box>

        <Box w="full" h="full" flex="1" py="4">
          <Output />
        </Box>
      </styled.main>
    </Flex>
  )
}
