import {
  createComponent,
  createContext,
  mergeProps,
  useContext,
  type ComponentProps,
  type ValidComponent
} from "solid-js"
import { Dynamic } from "solid-js/web"

type GenericProps = Record<string, unknown>
type StyleRecipe = {
  (props?: GenericProps): Record<string, string>
  splitVariantProps: (props?: GenericProps) => any
}

export const createStyleContext = <R extends StyleRecipe>(recipe: R) => {
  const StyleContext = createContext<Record<string, string> | null>(null)

  const withProvider = <T extends ValidComponent, P = ComponentProps<T>>(
    Component: T,
    slot?: string
  ) => {
    const StyledComponent = (props: P & Parameters<R>[0]) => {
      const [variantProps, componentProps] = recipe.splitVariantProps(props)
      const styleProperties = recipe(variantProps)
      return (
        <StyleContext.Provider value={styleProperties}>
          <Dynamic
            component={Component}
            class={styleProperties?.[slot ?? ""]}
            {...componentProps}
          />
        </StyleContext.Provider>
      )
    }
    return StyledComponent
  }

  const withContext = <T extends ValidComponent, P = ComponentProps<T>>(
    Component: T,
    slot?: string
  ): T => {
    if (!slot) return Component
    const StyledComponent = (props: P) => {
      const styleProperties = useContext(StyleContext)
      return createComponent(
        // @ts-ignore
        Dynamic,
        mergeProps(props, { component: Component, class: styleProperties?.[slot ?? ""] })
      )
    }
    return StyledComponent as T
  }

  return {
    withProvider,
    withContext
  }
}
