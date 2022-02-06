package one.tunkshif.loxkt.type

import one.tunkshif.loxkt.Environment
import one.tunkshif.loxkt.Interpreter
import one.tunkshif.loxkt.Return
import one.tunkshif.loxkt.ast.Stmt

class LoxFunction(
    private val declaration: Stmt.Function,
    private val closure: Environment
) : LoxCallable {
    override val arity: Int = declaration.params.size

    override fun call(interpreter: Interpreter, arguments: List<Any?>): Any? {
        val environment = Environment(closure)
        declaration.params.forEachIndexed { index, token ->
            environment.define(token.lexeme, arguments[index])
        }
        try {
            interpreter.executeBlock(declaration.body, environment)
        } catch (returnValue: Return) {
            return returnValue.value
        }
        return null
    }

    override fun toString(): String = "<fun ${declaration.name.lexeme}/${declaration.params.size}>"
}