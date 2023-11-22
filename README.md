# Lox Project

Tree-walking interpreter written in Kotlin and bytecode virtual machine written in Zig for the Lox programming language from [Crafting Interpreters][0].

# Progress

- [x] `lox-kt`
- [ ] `lox-zg`
  - [x] local-scoped variable
  - [ ] control flow
  - [ ] function and closure
  - [ ] garbage collector
  - [ ] class-based OOP
  - [ ] compiling to WASM
- [ ] `lox-playground`
  - [ ] online playground

# Tasks

- [x] How to compile zig targeting wasm
- [x] How to work with zig build system
- [x] How to load wasm with js in the browser
- [ ] How to do benchmark with the original clox implementation

[0]: https://craftinginterpreters.com/
