package one.tunkshif.loxkt

import java.io.InputStreamReader
import java.nio.charset.Charset
import java.nio.file.Files
import java.nio.file.Paths
import kotlin.system.exitProcess

object Lox {
    private var hadError = false
    private var hadRuntimeError = false

    private val interpreter = Interpreter()

    fun runFile(path: String) {
        val bytes = Files.readAllBytes(Paths.get(path))
        run(bytes.toString(Charset.defaultCharset()))
        if (hadError) exitProcess(65)
        if (hadRuntimeError) exitProcess(70)
    }

    fun runPrompt() {
        val reader = InputStreamReader(System.`in`).buffered()
        while (true) {
            print("> ")
            reader.readLine()?.let { run(it) } ?: break
            hadError = false
        }
    }

    private fun run(source: String) {
        val scanner = Scanner(source)
        val tokens = scanner.scanTokens()
        val parser = Parser(tokens)
        val statements = parser.parse()
        val resolver = Resolver(interpreter)

        resolver.resolve(statements)
        if (hadError) return
        interpreter.interpret(statements)
    }

    fun error(line: Int, message: String) {
        report(line, "", message)
    }

    fun error(token: Token, message: String) {
        if (token.type == TokenType.EOF) {
            report(token.line, " at end", message)
        } else {
            report(token.line, " at '${token.lexeme}'", message)
        }
    }

    fun runtimeError(error: RuntimeError) {
        System.err.println("[line ${error.token.line}] ${error.message}")
        hadRuntimeError = true
    }

    private fun report(line: Int, where: String, message: String) {
        System.err.println("[line $line] Error $where: $message")
        hadError = true
    }
}

class RuntimeError(val token: Token, message: String) : RuntimeException(message)

fun main(args: Array<String>) {
    if (args.size > 1) {
        System.err.println("Usage: lox-kt [script]")
        exitProcess(64)
    } else if (args.size == 1) {
        Lox.runFile(args.first())
    } else {
        Lox.runPrompt()
    }
}