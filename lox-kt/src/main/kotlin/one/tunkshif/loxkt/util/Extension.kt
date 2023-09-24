package one.tunkshif.loxkt.util

inline fun <reified T> Boolean.choose(a: T, b: T): T = if (this) a else b