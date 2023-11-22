import { Component, ComponentProps } from "solid-js"

export const ZapIcon: Component<ComponentProps<"svg">> = (props) => {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24">
      <path
        d="M20.98 11.802a.995.995 0 0 0-.738-.771l-6.86-1.716l2.537-5.921a.998.998 0 0 0-.317-1.192a.996.996 0 0 0-1.234.024l-11 9a1 1 0 0 0 .39 1.744l6.719 1.681l-3.345 5.854A1.001 1.001 0 0 0 8 22a.995.995 0 0 0 .6-.2l12-9a1 1 0 0 0 .38-.998z"
        fill="currentColor"
      />
    </svg>
  )
}