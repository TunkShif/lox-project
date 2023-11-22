import { Code } from "@/components/ui/code"
import { store } from "@/store"
import { Flex, styled } from "styled-system/jsx"

export const Output = () => {
  return (
    <Flex flexDirection="column" gap="4">
      <styled.h2 fontSize="lg" fontWeight="medium">
        Trace Execution
      </styled.h2>
      <styled.pre mr="8" overflow="auto">
        <Code w="full" p="2" fontFamily="mono">
          {store.output}
        </Code>
      </styled.pre>
    </Flex>
  )
}
