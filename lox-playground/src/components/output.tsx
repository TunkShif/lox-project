import { Code } from "@/components/ui/code"
import { useStore } from "@/store"
import { Flex, styled } from "styled-system/jsx"

export const Output = () => {
  const [store] = useStore()

  return (
    <Flex h="full" flexDirection="column" gap="4">
      <styled.h2 fontSize="lg" fontWeight="medium">
        Trace Execution
      </styled.h2>

      <styled.pre mr="8" overflow="auto">
        <Code w="full" p="2">
          {store.output}
        </Code>
      </styled.pre>
    </Flex>
  )
}
