package one.tunkshif.loxkt.type

import one.tunkshif.loxkt.Interpreter

interface LoxCallable {
    val arity: Int
    fun call(interpreter: Interpreter, arguments: List<Any?>): Any?
}