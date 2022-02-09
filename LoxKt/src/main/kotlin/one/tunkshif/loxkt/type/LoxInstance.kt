package one.tunkshif.loxkt.type

import one.tunkshif.loxkt.RuntimeError
import one.tunkshif.loxkt.Token

class LoxInstance(
    private val klass: LoxClass
) {
    private val fields = mutableMapOf<String, Any?>()

    fun get(name: Token): Any? {
        if (fields.containsKey(name.lexeme)) {
            return fields[name.lexeme]
        }
        val method = klass.findMethod(name.lexeme)
        return method?.bind(this)
            ?: throw RuntimeError(name, "Undefined property '${name.lexeme}'.")
    }

    fun set(name: Token, value: Any?) {
        fields[name.lexeme] = value
    }

    override fun toString(): String = "<object ${klass.name}>"
}