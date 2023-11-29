/* @refresh reload */
import { render } from "solid-js/web"
import { App } from "./app"

import "./index.css"
import "@fontsource-variable/inter"
import { Lox } from "@/lib/lox"

Lox.init()

const root = document.getElementById("root")
render(() => <App />, root!)
