package one.tunkshif.loxkt.type

import one.tunkshif.loxkt.Environment
import one.tunkshif.loxkt.Interpreter
import one.tunkshif.loxkt.Return
import one.tunkshif.loxkt.ast.Stmt

class LoxFunction(
    private val declaration: Stmt.Function,
    private val closure: Environment,
    private val isInitializer: Boolean = false
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
            if (isInitializer) return closure.getAt(0, "this")
            return returnValue.value
        }
        if (isInitializer) {
            return closure.getAt(0, "init")
        }
        return null
    }

    fun bind(instance: LoxInstance): LoxFunction {
        val environment = Environment(closure)
        environment.define("this", instance)
        return LoxFunction(declaration, environment, isInitializer)
    }

    override fun toString(): String = "<fun ${declaration.name.lexeme}/${declaration.params.size}>"
}