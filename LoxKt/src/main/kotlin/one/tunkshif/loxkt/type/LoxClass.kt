package one.tunkshif.loxkt.type

import one.tunkshif.loxkt.Interpreter

class LoxClass(
    val name: String,
    val superclass: LoxClass?,
    private val methods: Map<String, LoxFunction>
) : LoxCallable {
    override val arity: Int = findMethod("init")?.arity ?: 0

    override fun call(interpreter: Interpreter, arguments: List<Any?>): Any {
        val instance = LoxInstance(this)
        val initializer = findMethod("init")
        initializer?.bind(instance)?.call(interpreter, arguments)
        return instance
    }

    fun findMethod(name: String): LoxFunction? {
        if (methods.containsKey(name)) {
            return methods[name]
        }
        superclass?.let {
            return superclass.findMethod(name)
        }
        return null
    }

    override fun toString(): String = "<class $name>"
}