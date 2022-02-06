package one.tunkshif.loxkt

import one.tunkshif.loxkt.util.choose

class Scanner(
    private val source: String,
) {
    private var start = 0
    private var current = 0
    private var line = 1
    private val tokens: MutableList<Token> = mutableListOf()

    private val digits = '0'..'9'
    private val alphabet = ('a'..'z').union('A'..'Z').plus('_')

    fun scanTokens(): List<Token> {
        while (!isAtEnd()) {
            start = current
            scanToken()
        }
        tokens.add(Token(TokenType.EOF, "", null, line))
        return tokens
    }

    private fun scanToken() {
        when (advance()) {
            '(' -> addToken(TokenType.LEFT_PAREN)
            ')' -> addToken(TokenType.RIGHT_PAREN)
            '{' -> addToken(TokenType.LEFT_BRACE)
            '}' -> addToken(TokenType.RIGHT_BRACE)
            ',' -> addToken(TokenType.COMMA)
            '.' -> addToken(TokenType.DOT)
            '-' -> addToken(TokenType.MINUS)
            '+' -> addToken(TokenType.PLUS)
            ';' -> addToken(TokenType.SEMICOLON)
            '*' -> addToken(TokenType.STAR)
            '!' -> addToken(match('=').choose(TokenType.BANG_EQUAL, TokenType.BANG))
            '=' -> addToken(match('=').choose(TokenType.EQUAL_EQUAL, TokenType.EQUAL))
            '>' -> addToken(match('=').choose(TokenType.GREATER_EQUAL, TokenType.GREATER))
            '<' -> addToken(match('=').choose(TokenType.LESS_EQUAL, TokenType.LESS))
            '/' -> if (match('/')) {
                while (peek() != '\n' && !isAtEnd()) advance()
            } else {
                addToken(TokenType.SLASH)
            }
            ' ', '\r', '\t' -> return
            '\n' -> line++
            '"' -> string()
            in digits -> number()
            in alphabet -> identifier()
            else -> Lox.error(line, "Unexpected character.")
        }
    }

    private fun addToken(type: TokenType, literal: Any? = null) {
        val text = source.substring(start, current)
        tokens.add(Token(type, text, literal, line))
    }

    private fun isAtEnd() = current >= source.length
    private fun advance() = source[current++]
    private fun peek() = if (isAtEnd()) 0.toChar() else source[current]
    private fun peekNext() = if (current + 1 >= source.length) 0.toChar() else source[current + 1]
    private fun match(expected: Char): Boolean {
        if (isAtEnd()) return false
        if (source[current] != expected) return false
        current++
        return true
    }

    private fun isDigit(ch: Char) = ch in digits
    private fun isAlpha(ch: Char) = ch in alphabet
    private fun isAlphaNumeric(ch: Char) = isAlpha(ch) || isDigit(ch)

    private fun string() {
        while (peek() != '"' && !isAtEnd()) {
            if (peek() == '\n') line++
            advance()
        }
        if (isAtEnd()) {
            Lox.error(line, "Unterminated string.")
            return
        }
        advance()
        val value = source.substring(start + 1, current - 1)
        addToken(TokenType.STRING, value)
    }

    private fun number() {
        while (isDigit(peek())) advance()
        if (peek() == '.' && isDigit(peekNext())) {
            advance()
            while (isDigit(peek())) advance()
        }
        val value = source.substring(start, current).toDouble()
        addToken(TokenType.NUMBER, value)
    }

    private fun identifier() {
        while (isAlphaNumeric(peek())) advance()
        val text = source.substring(start, current)
        val type = keywords.getOrDefault(text, TokenType.IDENTIFIER)
        addToken(type)
    }

    companion object {
        private val keywords = mapOf(
            "and" to TokenType.AND,
            "class" to TokenType.CLASS,
            "else" to TokenType.ELSE,
            "false" to TokenType.FALSE,
            "for" to TokenType.FOR,
            "fun" to TokenType.FUN,
            "if" to TokenType.IF,
            "nil" to TokenType.NIL,
            "or" to TokenType.OR,
            "print" to TokenType.PRINT,
            "return" to TokenType.RETURN,
            "super" to TokenType.SUPER,
            "this" to TokenType.THIS,
            "true" to TokenType.TRUE,
            "var" to TokenType.VAR,
            "while" to TokenType.WHILE
        )
    }
}
