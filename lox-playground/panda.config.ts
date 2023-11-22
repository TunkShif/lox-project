import { defineConfig } from "@pandacss/dev"
import { createPreset } from "@park-ui/panda-preset"

export default defineConfig({
  preflight: true,
  presets: [
    "@pandacss/preset-base",
    createPreset({
      accentColor: "gold",
      grayColor: "neutral",
      borderRadius: "xs"
    })
  ],
  include: ["./src/**/*.{js,jsx,ts,tsx}"],
  exclude: [],
  theme: {
    extend: {
      tokens: {
        fonts: {
          sans: { value: "'Inter Variable', sans-serif" },
          code: { value: "Inconsolata, monospace" }
        }
      }
    }
  },
  jsxFramework: "solid",
  outdir: "styled-system"
})
