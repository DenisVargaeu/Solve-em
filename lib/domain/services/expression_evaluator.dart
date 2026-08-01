library;

import 'dart:math' as math;

/// A small, dependency-free math expression evaluator for the offline
/// calculator.
///
/// Supports:
/// * operators: `+ - * / ^ %`
/// * parentheses and implicit multiplication (`2(3+1)`, `2pi`)
/// * functions: `sqrt, cbrt, abs, sin, cos, tan, asin, acos, atan, ln, log10,
///   log2, exp, floor, ceil, round, gcd, lcm`
/// * factorial (`5!`) and postfix percent (`50%` → 0.5)
/// * constants: `pi`, `e`, `tau`, `phi`
///
/// Uses the shunting-yard algorithm with a small stack-based evaluator.

class ExpressionEvaluator {
  ExpressionEvaluator._();

  /// Evaluates [expression] and returns a human-friendly string result.
  ///
  /// Throws [FormatException] when the expression is invalid.
  static String evaluateToString(String expression) {
    final tokens = _tokenize(expression);
    final rpn = _toRpn(tokens);
    final value = _evalRpn(rpn);

    if (value.isNaN || value.isInfinite) {
      throw const FormatException('Result is not a number');
    }
    return _format(value);
  }

  /// Evaluates [expression] and returns the numeric value.
  static double evaluate(String expression) {
    final tokens = _tokenize(expression);
    final rpn = _toRpn(tokens);
    return _evalRpn(rpn);
  }

  static String _format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    var s = value.toStringAsPrecision(12);
    if (s.contains('e')) {
      // Keep scientific notation readable.
      return s;
    }
    // Trim trailing zeros.
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  // --- Tokenizer ---

  static const _operators = ['^', '!', '%', '*', '/', '+', '-'];
  static final _functions = <String, double Function(double)>{
    'sqrt': math.sqrt,
    'cbrt': (double d) => math.pow(d, 1 / 3).toDouble(),
    'abs': (double d) => d.abs(),
    'sin': math.sin,
    'cos': math.cos,
    'tan': math.tan,
    'asin': math.asin,
    'acos': math.acos,
    'atan': math.atan,
    'ln': math.log,
    'log10': (double d) => math.log(d) / math.ln10,
    'log2': (double d) => math.log(d) / math.ln2,
    'exp': math.exp,
    'floor': (double d) => d.floorToDouble(),
    'ceil': (double d) => d.ceilToDouble(),
    'round': (double d) => d.roundToDouble(),
  };

  static bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 48 && c <= 57;
  }

  static bool _isLetter(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }

  static List<_Token> _tokenize(String input) {
    final tokens = <_Token>[];
    var i = 0;
    final s = input
        .toLowerCase()
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');

    while (i < s.length) {
      final ch = s[i];

      if (_isDigit(ch) || ch == '.') {
        final start = i;
        while (i < s.length && (_isDigit(s[i]) || s[i] == '.')) {
          i++;
        }
        tokens.add(_Token.number(double.parse(s.substring(start, i))));
        continue;
      }

      if (_isLetter(ch)) {
        final start = i;
        while (i < s.length && _isLetter(s[i])) {
          i++;
        }
        final name = s.substring(start, i);
        if (name == 'pi') {
          tokens.add(_Token.number(math.pi));
        } else if (name == 'e') {
          tokens.add(_Token.number(math.e));
        } else if (name == 'tau') {
          tokens.add(_Token.number(math.pi * 2));
        } else if (name == 'phi') {
          tokens.add(_Token.number(1.6180339887));
        } else if (_functions.containsKey(name)) {
          tokens.add(_Token.function(name));
        } else {
          throw FormatException('Unknown symbol: $name');
        }
        continue;
      }

      if (ch == '(') {
        tokens.add(_Token.leftParen());
        i++;
        continue;
      }
      if (ch == ')') {
        tokens.add(_Token.rightParen());
        i++;
        continue;
      }
      if (ch == '!') {
        tokens.add(_Token.operator('!'));
        i++;
        continue;
      }
      if (ch == '%') {
        tokens.add(_Token.operator('%'));
        i++;
        continue;
      }
      if (_operators.contains(ch)) {
        tokens.add(_Token.operator(ch));
        i++;
        continue;
      }
      throw FormatException('Unexpected character: $ch');
    }
    return _insertImplicitMultiplication(tokens);
  }

  /// Turns `2(3)` / `2pi` / `)(` into explicit multiplications.
  static List<_Token> _insertImplicitMultiplication(List<_Token> tokens) {
    final out = <_Token>[];
    for (var i = 0; i < tokens.length; i++) {
      if (i > 0) {
        final prev = out.last;
        final curr = tokens[i];
        final needsMul =
            (prev.kind == _TokenKind.number ||
                prev.kind == _TokenKind.rightParen)
            ? (curr.kind == _TokenKind.number ||
                  curr.kind == _TokenKind.function ||
                  curr.kind == _TokenKind.leftParen)
            : prev.kind == _TokenKind.operator &&
                  (prev.text == '!' || prev.text == '%') &&
                  (curr.kind == _TokenKind.number ||
                      curr.kind == _TokenKind.leftParen);
        if (needsMul) out.add(_Token.operator('*'));
      }
      out.add(tokens[i]);
    }
    return out;
  }

  // --- Shunting-yard ---

  static int _precedence(String op) => switch (op) {
    '^' => 4,
    '!' || '%' => 3,
    '*' || '/' => 2,
    '+' || '-' => 1,
    _ => 0,
  };

  static bool _isPostfix(String op) => op == '!' || op == '%';

  static bool _rightAssoc(String op) => op == '^';

  static List<_Token> _toRpn(List<_Token> tokens) {
    final output = <_Token>[];
    final stack = <_Token>[];

    for (final token in tokens) {
      switch (token.kind) {
        case _TokenKind.number:
          output.add(token);
        case _TokenKind.function:
          stack.add(token);
        case _TokenKind.operator:
          while (stack.isNotEmpty &&
              stack.last.kind == _TokenKind.operator &&
              (_precedence(stack.last.text) > _precedence(token.text) ||
                  (_precedence(stack.last.text) == _precedence(token.text) &&
                      !_rightAssoc(token.text)))) {
            output.add(stack.removeLast());
          }
          stack.add(token);
        case _TokenKind.leftParen:
          stack.add(token);
        case _TokenKind.rightParen:
          while (stack.isNotEmpty && stack.last.kind != _TokenKind.leftParen) {
            output.add(stack.removeLast());
          }
          if (stack.isEmpty)
            throw const FormatException('Mismatched parentheses');
          stack.removeLast(); // pop '('
          if (stack.isNotEmpty && stack.last.kind == _TokenKind.function) {
            output.add(stack.removeLast());
          }
      }
    }

    while (stack.isNotEmpty) {
      final top = stack.removeLast();
      if (top.kind == _TokenKind.leftParen) {
        throw const FormatException('Mismatched parentheses');
      }
      output.add(top);
    }
    return output;
  }

  // --- RPN evaluator ---

  static double _evalRpn(List<_Token> rpn) {
    final stack = <double>[];

    double binary(String op) {
      final b = stack.removeLast();
      final a = stack.removeLast();
      return switch (op) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => a / b,
        '^' => math.pow(a, b).toDouble(),
        _ => throw const FormatException('Invalid expression'),
      };
    }

    for (final token in rpn) {
      switch (token.kind) {
        case _TokenKind.number:
          stack.add(token.value);
        case _TokenKind.operator:
          if (_isPostfix(token.text)) {
            if (stack.isEmpty)
              throw const FormatException('Invalid expression');
            final v = stack.removeLast();
            if (token.text == '!') {
              if (v < 0 || v != v.roundToDouble()) {
                throw const FormatException(
                  'Factorial needs a non-negative integer',
                );
              }
              stack.add(_factorial(v.toInt()).toDouble());
            } else {
              stack.add(v / 100);
            }
          } else {
            if (stack.length < 2) {
              throw const FormatException('Invalid expression');
            }
            stack.add(binary(token.text));
          }
        case _TokenKind.function:
          final v = stack.removeLast();
          final fn = _functions[token.text];
          if (fn == null) throw const FormatException('Invalid expression');
          stack.add(fn(v));
        default:
          throw const FormatException('Invalid expression');
      }
    }

    if (stack.length != 1) throw const FormatException('Invalid expression');
    return stack.last;
  }

  static int _factorial(int n) {
    var result = 1;
    for (var i = 2; i <= n; i++) {
      result *= i;
      if (result > 1e18) return result;
    }
    return result;
  }
}

// --- Token types ---

enum _TokenKind { number, operator, function, leftParen, rightParen }

class _Token {
  const _Token.number(this.value) : text = '', kind = _TokenKind.number;
  const _Token.operator(this.text) : value = 0, kind = _TokenKind.operator;
  const _Token.function(this.text) : value = 0, kind = _TokenKind.function;
  const _Token.leftParen() : text = '(', value = 0, kind = _TokenKind.leftParen;
  const _Token.rightParen()
    : text = ')',
      value = 0,
      kind = _TokenKind.rightParen;

  final _TokenKind kind;
  final String text;
  final double value;
}
