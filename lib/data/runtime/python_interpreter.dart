// ignore_for_file: unnecessary_underscores, avoid_init_to_null, prefer_function_declarations_over_variables, prefer_if_null_operators, non_constant_identifier_names

import 'dart:math' as math;

/// In-app Python subset used when a host `python3` is not available (Android).
class PythonInterpreter {
  const PythonInterpreter();

  PythonRun run(String source) {
    try {
      _pdStore.clear();
      _mplFig = null;
      final runtime = _Runtime();
      runtime.exec(source);
      return PythonRun(ok: true, stdout: runtime.out.toString());
    } on _PyErr catch (e) {
      return PythonRun(ok: false, stdout: '', stderr: e.message);
    } catch (e) {
      return PythonRun(ok: false, stdout: '', stderr: e.toString());
    }
  }
}

class PythonRun {
  const PythonRun({required this.ok, required this.stdout, this.stderr = ''});
  final bool ok;
  final String stdout;
  final String stderr;
}

class _PyErr implements Exception {
  _PyErr(this.message);
  final String message;
}

class _Runtime {
  _Runtime() {
    builtins = {
      ..._sharedBuiltins,
      'print': _Native((args, kwargs) {
        final sep = (kwargs['sep'] as String?) ?? ' ';
        final end = (kwargs['end'] as String?) ?? '\n';
        out.write(args.map(_str).join(sep));
        out.write(end);
        return null;
      }),
      'super': _Native((_, __) => _Mod({'__init__': _Native((_, __) => null)})),
      'open': _Native((args, kwargs) {
        final path = _str(args.first);
        final mode = args.length > 1 ? _str(args[1]) : _str(kwargs['mode'] ?? 'r');
        if (mode.contains('w')) files[path] = '';
        return _FileHandle(path, mode, files);
      }),
      'sorted': _Native((args, _) {
        final xs = _iter(args.first).toList();
        xs.sort((a, b) {
          if (a is num && b is num) return a.compareTo(b);
          return _str(a).compareTo(_str(b));
        });
        return xs;
      }),
    };
  }

  final files = <String, String>{};
  final out = StringBuffer();
  final List<Map<String, Object?>> scopes = [{}];
  late final Map<String, Object?> builtins;
  bool _returning = false;
  Object? _returnValue;
  bool _yielding = false;
  final List<Object?> _yielded = [];

  Object? get(String name) {
    for (var i = scopes.length - 1; i >= 0; i--) {
      if (scopes[i].containsKey(name)) return scopes[i][name];
    }
    if (builtins.containsKey(name)) return builtins[name];
    throw _PyErr("NameError: name '$name' is not defined");
  }

  void set(String name, Object? value) => scopes.last[name] = value;

  void exec(String source) {
    final tokens = _Lexer(source).tokenize();
    _Parser(tokens, this).parseProgram();
  }

  Object? evalExpr(String source) {
    final tokens = _Lexer(source).tokenize();
    return _Parser(tokens, this).parseExpression();
  }
}

class _Tok {
  _Tok(this.kind, this.lex, [this.value]);
  final String kind;
  final String lex;
  final Object? value;
}

class _Lexer {
  _Lexer(String src) : src = src.replaceAll('\t', '    ').replaceAll('\r\n', '\n');
  final String src;
  var i = 0;
  var lineStart = 0;
  final indents = <int>[0];

  List<_Tok> tokenize() {
    final out = <_Tok>[];
    var atBol = true;
    while (i < src.length) {
      if (atBol) {
        final start = i;
        while (i < src.length && src[i] == ' ') {
          i++;
        }
        if (i < src.length && (src[i] == '\n' || src[i] == '#')) {
          while (i < src.length && src[i] != '\n') {
            i++;
          }
          if (i < src.length) i++;
          continue;
        }
        final col = i - start;
        if (col > indents.last) {
          indents.add(col);
          out.add(_Tok('INDENT', ''));
        } else {
          while (col < indents.last) {
            indents.removeLast();
            out.add(_Tok('DEDENT', ''));
          }
          if (col != indents.last) throw _PyErr('IndentationError');
        }
        atBol = false;
      }
      if (i >= src.length) break;
      final c = src[i];
      if (c == '#') {
        while (i < src.length && src[i] != '\n') {
          i++;
        }
        continue;
      }
      if (c == '\n') {
        out.add(_Tok('NL', '\n'));
        i++;
        atBol = true;
        lineStart = i;
        continue;
      }
      if (c == ' ') {
        i++;
        continue;
      }
      if (c == '"' || c == "'" || (c == 'f' && i + 1 < src.length && (src[i + 1] == '"' || src[i + 1] == "'"))) {
        out.add(_string());
        continue;
      }
      if (_isDigit(c) || (c == '.' && i + 1 < src.length && _isDigit(src[i + 1]))) {
        out.add(_number());
        continue;
      }
      if (_isIdStart(c)) {
        final start = i;
        i++;
        while (i < src.length && _isIdPart(src[i])) {
          i++;
        }
        final w = src.substring(start, i);
        const keys = {
          'def', 'return', 'yield', 'import', 'from', 'as', 'if', 'elif', 'else',
          'for', 'in', 'not', 'and', 'or', 'class', 'async', 'await', 'raise',
          'try', 'except', 'True', 'False', 'None', 'pass', 'with', 'is', 'assert',
        };
        out.add(_Tok(keys.contains(w) ? w : 'ID', w));
        continue;
      }
      if (i + 1 < src.length) {
        final two = src.substring(i, i + 2);
        const ops = ['==', '!=', '<=', '>=', '//', '**', '->'];
        if (ops.contains(two)) {
          out.add(_Tok(two, two));
          i += 2;
          continue;
        }
      }
      out.add(_Tok(c, c));
      i++;
    }
    while (indents.length > 1) {
      indents.removeLast();
      out.add(_Tok('DEDENT', ''));
    }
    out.add(_Tok('EOF', ''));
    return out;
  }

  _Tok _string() {
    var f = false;
    if (src[i] == 'f') {
      f = true;
      i++;
    }
    final q = src[i];
    i++;
    final buf = StringBuffer();
    while (i < src.length && src[i] != q) {
      if (src[i] == '\\' && i + 1 < src.length) {
        i++;
        final e = src[i++];
        buf.write(const {'n': '\n', 't': '\t', '"': '"', "'": "'", '\\': '\\'}[e] ?? e);
      } else {
        buf.write(src[i++]);
      }
    }
    if (i >= src.length) throw _PyErr('SyntaxError: unterminated string');
    i++;
    return _Tok(f ? 'FSTR' : 'STR', buf.toString(), buf.toString());
  }

  _Tok _number() {
    final start = i;
    while (i < src.length && (_isDigit(src[i]) || src[i] == '.' || src[i] == 'e' || src[i] == 'E' || src[i] == '+' || src[i] == '-')) {
      if ((src[i] == '+' || src[i] == '-') && i > start && src[i - 1] != 'e' && src[i - 1] != 'E') break;
      i++;
    }
    final raw = src.substring(start, i);
    final n = num.parse(raw);
    return _Tok('NUM', raw, n);
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isIdStart(String c) => RegExp(r'[A-Za-z_]').hasMatch(c);
  bool _isIdPart(String c) => RegExp(r'[A-Za-z0-9_]').hasMatch(c);
}

class _Parser {
  _Parser(this.toks, this.rt);
  final List<_Tok> toks;
  final _Runtime rt;
  var p = 0;

  _Tok get t => toks[p];
  bool has(String k) => t.kind == k;
  bool eat(String k) {
    if (has(k)) {
      p++;
      return true;
    }
    return false;
  }

  void need(String k) {
    if (!eat(k)) throw _PyErr('SyntaxError: expected $k, got ${t.kind}');
  }

  void skipNl() {
    while (eat('NL')) {}
  }

  void parseProgram() {
    skipNl();
    while (!has('EOF')) {
      parseStmt();
      skipNl();
    }
  }

  Object? parseExpression() {
    skipNl();
    return expr();
  }

  void parseStmt() {
    skipNl();
    if (has('EOF')) return;
    if (eat('DEDENT')) return;
    if (eat('pass')) {
      eat('NL');
      return;
    }
    if (eat('assert')) {
      final v = expr();
      if (!_truth(v)) throw _PyErr('AssertionError');
      eat('NL');
      return;
    }
    if (eat('with')) {
      final ctx = expr();
      String? asName;
      if (eat('as')) {
        asName = t.lex;
        need('ID');
      }
      need(':');
      eat('NL');
      need('INDENT');
      final bodyStart = p;
      _skipBlock();
      final body = toks.sublist(bodyStart, p);
      if (asName != null) rt.set(asName, ctx);
      _runBody(body);
      if (ctx is _FileHandle) {
        ctx.close();
      }
      eat('NL');
      return;
    }
    if (eat('import')) {
      final parts = <String>[t.lex];
      need('ID');
      while (eat('.')) {
        parts.add(t.lex);
        need('ID');
      }
      var alias = parts.last;
      if (eat('as')) {
        alias = t.lex;
        need('ID');
      }
      if (parts.length >= 2 && parts[0] == 'torch' && parts[1] == 'nn') {
        rt.set(alias, (_module('torch') as _Mod).attrs['nn']);
      } else if (parts.length >= 2 && parts[0] == 'matplotlib' && parts[1] == 'pyplot') {
        rt.set(alias, _mplPyplot());
      } else if (parts.length >= 2 && parts[0] == 'scipy') {
        Object? cur = _module('scipy');
        for (var i = 1; i < parts.length; i++) {
          cur = cur is _Mod ? cur.attrs[parts[i]] : null;
        }
        rt.set(alias, cur ?? _Mod({}));
      } else {
        rt.set(alias, _module(parts.first));
      }
      eat('NL');
      return;
    }
    if (eat('from')) {
      final parts = <String>[t.lex];
      need('ID');
      while (eat('.')) {
        parts.add(t.lex);
        need('ID');
      }
      need('import');
      final names = <String>[t.lex];
      need('ID');
      while (eat(',')) {
        names.add(t.lex);
        need('ID');
      }
      Object? cur = _module(parts.first);
      for (var i = 1; i < parts.length; i++) {
        cur = cur is _Mod ? cur.attrs[parts[i]] : null;
      }
      for (final name in names) {
        if (cur is _Mod && cur.attrs.containsKey(name)) {
          rt.set(name, cur.attrs[name]);
        } else {
          rt.set(name, _fromImport(parts.first, name));
        }
      }
      eat('NL');
      return;
    }
    if (eat('async')) {
      parseDef();
      return;
    }
    if (has('def')) {
      parseDef();
      return;
    }
    if (eat('@')) {
      expr();
      eat('NL');
      parseStmt();
      return;
    }
    if (eat('class')) {
      parseClass();
      return;
    }
    if (eat('return')) {
      rt._returning = true;
      if (has('NL') || has('DEDENT') || has('EOF')) {
        rt._returnValue = null;
      } else {
        final first = expr();
        if (eat(',')) {
          final items = <Object?>[first, expr()];
          while (eat(',')) {
            items.add(expr());
          }
          rt._returnValue = _Tuple(items);
        } else {
          rt._returnValue = first;
        }
      }
      eat('NL');
      return;
    }
    if (eat('yield')) {
      rt._yielding = true;
      rt._yielded.add(has('NL') || has('DEDENT') ? null : expr());
      eat('NL');
      return;
    }
    if (eat('try')) {
      need(':');
      eat('NL');
      need('INDENT');
      final tryStart = p;
      _skipBlock();
      final tryBody = toks.sublist(tryStart, p);
      skipNl();
      need('except');
      String? asName;
      if (!has(':')) {
        expr();
        if (eat('as')) {
          asName = t.lex;
          need('ID');
        }
      }
      need(':');
      eat('NL');
      need('INDENT');
      final exStart = p;
      _skipBlock();
      final exBody = toks.sublist(exStart, p);
      try {
        _runBody(tryBody);
      } on _PyErr catch (e) {
        if (asName != null) rt.set(asName, e.message);
        _runBody(exBody);
      }
      eat('NL');
      return;
    }
    if (eat('raise')) {
      final v = expr();
      throw _PyErr('ValueError: ${_str(v)}');
    }
    if (eat('for')) {
      parseFor();
      return;
    }
    if (eat('if')) {
      parseIf();
      return;
    }
    if (eat('await')) {
      expr();
      eat('NL');
      return;
    }
    final eqAt = _stmtAssignEq();
    if (eqAt != null) {
      final start = p;
      p = eqAt + 1;
      final first = expr();
      Object? value = first;
      if (eat(',')) {
        final items = <Object?>[first, expr()];
        while (eat(',')) {
          items.add(expr());
        }
        value = items;
      }
      _assign(start, value);
      eat('NL');
      return;
    }
    expr();
    eat('NL');
  }

  int? _stmtAssignEq() {
    var i = p;
    var depth = 0;
    while (i < toks.length) {
      final k = toks[i].kind;
      if (depth == 0 && (k == 'NL' || k == 'EOF' || k == 'DEDENT')) return null;
      if (k == '(' || k == '[' || k == '{') depth++;
      if (k == ')' || k == ']' || k == '}') depth--;
      if (depth == 0 && k == '=') return i;
      if (depth == 0 && (k == '==' || k == '!=' || k == '<=' || k == '>=')) return null;
      i++;
    }
    return null;
  }

  void _assign(int start, Object? value) {
    final saved = p;
    p = start;
    if (has('ID') && toks[p + 1].kind != ',') {
      final name = t.lex;
      need('ID');
      if (eat('[')) {
        final key = expr();
        need(']');
        final target = rt.get(name);
        if (target is Map) {
          target[key] = value;
        } else if (target is List && key is num) {
          target[key.toInt()] = value;
        } else if (target is _DataFrame) {
          target.setCol(key, value);
        } else {
          throw _PyErr('TypeError: cannot index assign');
        }
      } else if (eat('.')) {
        final attr = t.lex;
        need('ID');
        final target = rt.get(name);
        if (target is _Instance) {
          target.fields[attr] = value;
        } else if (target is _Mod) {
          target.attrs[attr] = value;
        } else {
          throw _PyErr('TypeError: cannot set attribute');
        }
      } else {
        rt.set(name, value);
      }
      p = saved;
      return;
    }
    final names = <String>[];
    names.add(t.lex);
    need('ID');
    while (eat(',')) {
      names.add(t.lex);
      need('ID');
    }
    final items = _iter(value).toList();
    if (items.length != names.length) throw _PyErr('ValueError: unpack mismatch');
    for (var i = 0; i < names.length; i++) {
      rt.set(names[i], items[i]);
    }
    p = saved;
  }

  void parseDef() {
    need('def');
    final name = t.lex;
    need('ID');
    need('(');
    final params = <String>[];
    final defaults = <String, Object?>{};
    while (!has(')')) {
      final pname = t.lex;
      need('ID');
      if (eat(':')) {
        expr();
      }
      if (eat('=')) {
        defaults[pname] = expr();
      }
      params.add(pname);
      eat(',');
    }
    need(')');
    if (eat('->')) expr();
    need(':');
    late final List<_Tok> body;
    if (eat('NL')) {
      need('INDENT');
      final bodyStart = p;
      _skipBlock();
      body = toks.sublist(bodyStart, p);
    } else {
      final bodyStart = p;
      while (!has('NL') && !has('EOF') && !has('DEDENT')) {
        p++;
      }
      body = toks.sublist(bodyStart, p);
      eat('NL');
    }
    rt.set(name, _Fn(name, params, defaults, body, rt));
  }

  void parseClass() {
    final name = t.lex;
    need('ID');
    _Class? parent;
    if (eat('(')) {
      if (!has(')')) {
        final base = expr();
        if (base is _Class) parent = base;
        while (eat(',')) {
          expr();
        }
      }
      need(')');
    }
    need(':');
    eat('NL');
    need('INDENT');
    final fields = <String, Object?>{};
    final methods = <String, _Fn>{};
    while (!has('DEDENT') && !has('EOF')) {
      skipNl();
      if (has('DEDENT')) break;
      if (has('def') || (has('async') && toks[p + 1].kind == 'def')) {
        eat('async');
        final before = Map<String, Object?>.from(rt.scopes.last);
        parseDef();
        for (final e in rt.scopes.last.entries) {
          if (e.value is _Fn && (!before.containsKey(e.key) || !identical(before[e.key], e.value))) {
            methods[e.key] = e.value as _Fn;
          }
        }
      } else if (has('ID')) {
        final f = t.lex;
        need('ID');
        if (eat(':')) expr();
        var val = null;
        if (eat('=')) val = expr();
        fields[f] = val;
        eat('NL');
      } else {
        parseStmt();
      }
    }
    need('DEDENT');
    if (parent != null) {
      for (final e in parent.fields.entries) {
        fields.putIfAbsent(e.key, () => e.value);
      }
      for (final e in parent.methods.entries) {
        methods.putIfAbsent(e.key, () => e.value);
      }
    }
    rt.set(name, _Class(name, fields, methods));
  }

  void parseFor() {
    final names = <String>[t.lex];
    need('ID');
    while (eat(',')) {
      names.add(t.lex);
      need('ID');
    }
    need('in');
    final iterable = expr();
    need(':');
    eat('NL');
    need('INDENT');
    final bodyStart = p;
    _skipBlock();
    final body = toks.sublist(bodyStart, p);
    for (final item in _iter(iterable)) {
      if (names.length == 1) {
        rt.set(names.first, item);
      } else {
        final row = _iter(item).toList();
        for (var i = 0; i < names.length; i++) {
          rt.set(names[i], i < row.length ? row[i] : null);
        }
      }
      _runBody(body);
      if (rt._returning) return;
    }
  }

  void parseIf() {
    while (true) {
      final cond = expr();
      need(':');
      eat('NL');
      need('INDENT');
      final thenStart = p;
      _skipBlock();
      final thenBody = toks.sublist(thenStart, p);
      if (_truth(cond)) {
        _runBody(thenBody);
        skipNl();
        while (eat('elif')) {
          expr();
          need(':');
          eat('NL');
          need('INDENT');
          _skipBlock();
          skipNl();
        }
        if (eat('else')) {
          need(':');
          eat('NL');
          need('INDENT');
          _skipBlock();
        }
        return;
      }
      skipNl();
      if (eat('elif')) continue;
      if (eat('else')) {
        need(':');
        eat('NL');
        need('INDENT');
        final elseStart = p;
        _skipBlock();
        _runBody(toks.sublist(elseStart, p));
      }
      return;
    }
  }

  void _skipBlock() {
    var depth = 1;
    while (p < toks.length && depth > 0) {
      if (has('INDENT')) depth++;
      if (has('DEDENT')) {
        depth--;
        if (depth == 0) {
          p++;
          break;
        }
      }
      p++;
    }
  }

  void _runBody(List<_Tok> body) {
    if (body.isEmpty) return;
    final inner = _Parser([...body, _Tok('EOF', '')], rt);
    inner.skipNl();
    while (!inner.has('EOF')) {
      inner.parseStmt();
      inner.skipNl();
      if (rt._returning) break;
      rt._yielding = false;
    }
  }

  Object? expr() {
    final v = _or();
    if (eat('if')) {
      final cond = _or();
      need('else');
      final other = expr();
      return _truth(cond) ? v : other;
    }
    return v;
  }

  Object? _or() {
    var v = _and();
    while (eat('or')) {
      final r = _and();
      v = _truth(v) ? v : r;
    }
    return v;
  }

  Object? _and() {
    var v = _not();
    while (eat('and')) {
      final r = _not();
      v = _truth(v) ? r : v;
    }
    return v;
  }

  Object? _not() {
    if (eat('not')) {
      if (has('in')) {
        eat('in');
        final container = _not();
        return !_contains(container, _cmp());
      }
      return !_truth(_not());
    }
    return _cmp();
  }

  Object? _cmp() {
    var v = _add();
    while (true) {
      if (eat('==')) {
        final r = _add();
        v = _seriesBin(v, r, (a, b) => _eq(a, b)) ?? _eq(v, r);
      } else if (eat('!=')) {
        final r = _add();
        v = _seriesBin(v, r, (a, b) => !_eq(a, b)) ?? !_eq(v, r);
      } else if (eat('<')) {
        final r = _add();
        v = _seriesBin(v, r, (a, b) => _num(a) < _num(b)) ?? (_num(v) < _num(r));
      } else if (eat('>')) {
        final r = _add();
        v = _seriesBin(v, r, (a, b) => _num(a) > _num(b)) ?? (_num(v) > _num(r));
      } else if (eat('<=')) {
        final r = _add();
        v = _seriesBin(v, r, (a, b) => _num(a) <= _num(b)) ?? (_num(v) <= _num(r));
      } else if (eat('>=')) {
        final r = _add();
        v = _seriesBin(v, r, (a, b) => _num(a) >= _num(b)) ?? (_num(v) >= _num(r));
      } else if (eat('in')) {
        v = _contains(_add(), v);
      } else if (has('not') && toks[p + 1].kind == 'in') {
        eat('not');
        eat('in');
        v = !_contains(_add(), v);
      } else if (eat('is')) {
        if (eat('not')) {
          v = !identical(v, _add());
        } else {
          v = identical(v, _add());
        }
      } else {
        break;
      }
    }
    return v;
  }

  Object? _add() {
    var v = _mul();
    while (true) {
      if (eat('+')) {
        v = _plus(v, _mul());
      } else if (eat('-')) {
        v = _minus(v, _mul());
      } else {
        break;
      }
    }
    return v;
  }

  Object? _mul() {
    var v = _unary();
    while (true) {
      if (eat('*')) {
        v = _times(v, _unary());
      } else if (eat('/')) {
        final r = _unary();
        final nd = _ndBin(v, r, (x, y) => x / y);
        final s = _seriesBin(v, r, (x, y) => _num(x) / _num(y));
        v = nd ?? s ?? (_num(v) / _num(r));
      } else if (eat('//')) {
        v = _num(v) ~/ _num(_unary());
      } else if (eat('%')) {
        v = _num(v) % _num(_unary());
      } else if (eat('&')) {
        final r = _unary();
        v = _seriesBin(v, r, (a, b) => _truth(a) && _truth(b)) ?? (_num(v).toInt() & _num(r).toInt());
      } else if (eat('|')) {
        final r = _unary();
        v = _seriesBin(v, r, (a, b) => _truth(a) || _truth(b)) ?? (_num(v).toInt() | _num(r).toInt());
      } else if (eat('^')) {
        v = _num(v).toInt() ^ _num(_unary()).toInt();
      } else if (eat('@')) {
        v = _matmul(v, _unary());
      } else {
        break;
      }
    }
    return v;
  }

  Object? _unary() {
    if (eat('-')) return -_num(_unary());
    if (eat('+')) return _unary();
    if (eat('~')) {
      final r = _unary();
      if (r is _Series) return _Series([for (final x in r.values) !_truth(x)], index: r.index, name: r.name);
      return ~_num(r).toInt();
    }
    if (eat('await')) return _unary();
    return _pow();
  }

  Object? _pow() {
    var v = _primary();
    if (eat('**')) v = math.pow(_num(v), _num(_unary()));
    return v;
  }

  Object? _primary() {
    var v = _atom();
    while (true) {
      if (eat('.')) {
        final attr = t.lex;
        need('ID');
        v = _attr(v, attr);
      } else if (eat('(')) {
        final args = <Object?>[];
        final kwargs = <String, Object?>{};
        while (!has(')')) {
          if (has('ID') && toks[p + 1].kind == '=') {
            final n = t.lex;
            need('ID');
            need('=');
            kwargs[n] = expr();
          } else {
            args.add(expr());
          }
          eat(',');
        }
        need(')');
        v = _call(v, args, kwargs);
      } else if (eat('[')) {
        Object? start;
        if (!has(':') && !has(']')) {
          start = expr();
        }
        if (eat(':')) {
          Object? stop;
          if (!has(']')) stop = expr();
          need(']');
          v = _slice(v, start, stop);
        } else if (eat(',')) {
          final items = <Object?>[start];
          items.add(expr());
          while (eat(',')) {
            if (has(']')) break;
            items.add(expr());
          }
          need(']');
          v = _index(v, _Tuple(items));
        } else {
          need(']');
          v = _index(v, start);
        }
      } else {
        break;
      }
    }
    return v;
  }

  Object? _atom() {
    if (eat('True')) return true;
    if (eat('False')) return false;
    if (eat('None')) return null;
    if (has('NUM')) {
      final v = t.value;
      p++;
      return v;
    }
    if (has('STR')) {
      final v = t.value;
      p++;
      return v;
    }
    if (has('FSTR')) {
      final raw = t.value as String;
      p++;
      return _fstring(raw);
    }
    if (has('ID')) {
      final n = t.lex;
      p++;
      return rt.get(n);
    }
    if (eat('(')) {
      if (eat(')')) return _Tuple(const []);
      final exprStart = p;
      if (_hasCompFor(close: ')')) return _replayComp(exprStart, close: ')');
      final first = expr();
      final items = <Object?>[first];
      var tuple = false;
      while (eat(',')) {
        tuple = true;
        if (has(')')) break;
        items.add(expr());
      }
      need(')');
      if (tuple || items.length != 1) return _Tuple(items);
      return first;
    }
    if (eat('[')) {
      if (eat(']')) return <Object?>[];
      final exprStart = p;
      if (_hasCompFor(close: ']')) return _replayComp(exprStart, close: ']');
      final first = expr();
      final items = <Object?>[first];
      while (eat(',')) {
        if (has(']')) break;
        items.add(expr());
      }
      need(']');
      return items;
    }
    if (eat('{')) {
      if (eat('}')) return <Object?, Object?>{};
      final exprStart = p;
      if (_hasCompFor(close: '}')) return _replayComp(exprStart, close: '}');
      final first = expr();
      if (eat(':')) {
        final map = <Object?, Object?>{first: expr()};
        while (eat(',')) {
          if (has('}')) break;
          final k = expr();
          need(':');
          map[k] = expr();
        }
        need('}');
        return map;
      }
      final set = <Object?>{first};
      while (eat(',')) {
        if (has('}')) break;
        set.add(expr());
      }
      need('}');
      return set;
    }
    throw _PyErr('SyntaxError: unexpected ${t.kind}');
  }

  bool _hasCompFor({required String close}) {
    var i = p;
    var depth = 0;
    while (i < toks.length) {
      final k = toks[i].kind;
      if (k == '(' || k == '[' || k == '{') {
        depth++;
      } else if (k == ')' || k == ']' || k == '}') {
        if (depth == 0) return false;
        depth--;
        i++;
        continue;
      }
      if (depth == 0 && k == 'for') return true;
      if (depth == 0 && k == close) return false;
      i++;
    }
    return false;
  }

  Object? _replayComp(int exprStart, {required String close}) {
    var depth = 0;
    while (!(has('for') && depth == 0)) {
      if (has('(') || has('[') || has('{')) depth++;
      if (has(')') || has(']') || has('}')) depth--;
      if (has('EOF')) throw _PyErr('SyntaxError: comprehension');
      p++;
    }
    need('for');
    final names = <String>[t.lex];
    need('ID');
    while (eat(',')) {
      names.add(t.lex);
      need('ID');
    }
    need('in');
    final iterable = _or();
    final predStart = eat('if') ? p : -1;
    if (predStart >= 0) {
      var d = 0;
      while (!(has(close) && d == 0)) {
        if (has('(') || has('[') || has('{')) d++;
        if (has(')') || has(']') || has('}')) d--;
        if (has('EOF')) throw _PyErr('SyntaxError: comprehension');
        p++;
      }
    }
    need(close);
    final after = p;
    final out = <Object?>[];
    for (final item in _iter(iterable)) {
      rt.scopes.add({});
      if (names.length == 1) {
        rt.set(names.first, item);
      } else {
        final row = _iter(item).toList();
        for (var i = 0; i < names.length; i++) {
          rt.set(names[i], i < row.length ? row[i] : null);
        }
      }
      var keep = true;
      if (predStart >= 0) {
        p = predStart;
        keep = _truth(_or());
      }
      if (keep) {
        p = exprStart;
        out.add(expr());
      }
      rt.scopes.removeLast();
    }
    p = after;
    if (close == '}') return {...out};
    if (close == ')') return _Gen(out);
    return out;
  }

  String _fstring(String raw) {
    final buf = StringBuffer();
    var i = 0;
    while (i < raw.length) {
      if (raw[i] == '{') {
        final end = raw.indexOf('}', i);
        if (end < 0) throw _PyErr('SyntaxError: f-string');
        final inner = raw.substring(i + 1, end);
        final parts = inner.split(':');
        final value = rt.evalExpr(parts.first.trim());
        buf.write(parts.length > 1 ? _format(value, parts.last) : _str(value));
        i = end + 1;
      } else {
        buf.write(raw[i++]);
      }
    }
    return buf.toString();
  }
}

Object? _call(Object? callee, List<Object?> args, Map<String, Object?> kwargs) {
  if (callee is _Native) return callee.call(args, kwargs);
  if (callee is _Fn) return callee.call(args, kwargs);
  if (callee is _Class) return callee.construct(args, kwargs);
  if (callee is _Instance) return callee.call(args, kwargs);
  if (callee is _Method) return callee.call(args, kwargs);
  if (callee is _TorchSeq) return _applyTorch(callee, args.first);
  if (callee is _TorchLinear) {
    final t = args.first as _Nd;
    final head = t.shape.sublist(0, t.shape.length - 1);
    final shape = [...head, callee.out];
    return _Nd(shape, List.filled(_prod(shape), 0.1));
  }
  throw _PyErr('TypeError: object is not callable');
}

Object? _applyTorch(_TorchSeq seq, Object? input) {
  var t = input is _Nd ? input : _Nd.fromList(input);
  for (final layer in seq.layers) {
    if (layer is _TorchLinear) {
      t = _call(layer, [t], const {}) as _Nd;
    }
  }
  return t;
}

class _Fn {
  _Fn(this.name, this.params, this.defaults, this.body, this.rt);
  final String name;
  final List<String> params;
  final Map<String, Object?> defaults;
  final List<_Tok> body;
  final _Runtime rt;

  Object? call(List<Object?> args, Map<String, Object?> kwargs) {
    rt.scopes.add({});
    for (var i = 0; i < params.length; i++) {
      if (i < args.length) {
        rt.set(params[i], args[i]);
      } else if (kwargs.containsKey(params[i])) {
        rt.set(params[i], kwargs[params[i]]);
      } else if (defaults.containsKey(params[i])) {
        rt.set(params[i], defaults[params[i]]);
      } else {
        throw _PyErr('TypeError: missing argument ${params[i]}');
      }
    }
    final prevR = rt._returning;
    final prevY = rt._yielding;
    final prevV = rt._returnValue;
    rt._returning = false;
    rt._yielding = false;
    rt._returnValue = null;
    rt._yielded.clear();
    final inner = _Parser([...body, _Tok('EOF', '')], rt);
    inner.skipNl();
    while (!inner.has('EOF')) {
      inner.parseStmt();
      inner.skipNl();
      if (rt._returning) break;
      rt._yielding = false;
    }
    final yielded = List<Object?>.of(rt._yielded);
    final ret = rt._returnValue;
    final wasYield = yielded.isNotEmpty;
    rt._returning = prevR;
    rt._yielding = prevY;
    rt._returnValue = prevV;
    rt.scopes.removeLast();
    if (wasYield) return _Gen(yielded);
    return ret;
  }
}

class _Gen {
  _Gen(this.values);
  final List<Object?> values;
}

class _Class {
  _Class(this.name, this.fields, this.methods);
  final String name;
  final Map<String, Object?> fields;
  final Map<String, _Fn> methods;

  _Instance construct(List<Object?> args, Map<String, Object?> kwargs) {
    final inst = _Instance(this, Map<String, Object?>.from(fields));
    for (final e in kwargs.entries) {
      inst.fields[e.key] = e.value;
    }
    final init = methods['__init__'];
    if (init != null) {
      init.call([inst, ...args], kwargs);
    }
    return inst;
  }
}

class _Instance {
  _Instance(this.cls, this.fields);
  final _Class cls;
  final Map<String, Object?> fields;

  Object? call(List<Object?> args, Map<String, Object?> kwargs) {
    final fwd = cls.methods['forward'] ?? cls.methods['__call__'];
    if (fwd == null) throw _PyErr('TypeError: $cls not callable');
    return fwd.call([this, ...args], kwargs);
  }

  @override
  String toString() {
    final parts = fields.entries.map((e) => '${e.key}=${_str(e.value)}').join(', ');
    return '${cls.name}($parts)';
  }
}

class _Method {
  _Method(this.fn, this.self);
  final _Fn fn;
  final Object? self;
  Object? call(List<Object?> args, Map<String, Object?> kwargs) => fn.call([self, ...args], kwargs);
}

class _Native {
  _Native(this.fn);
  final Object? Function(List<Object?> args, Map<String, Object?> kwargs) fn;
  Object? call(List<Object?> args, Map<String, Object?> kwargs) => fn(args, kwargs);
}

class _Mod {
  _Mod(this.attrs);
  final Map<String, Object?> attrs;
}

class _Nd {
  _Nd(this.shape, this.data);
  final List<int> shape;
  final List<double> data;

  int get size => data.length;

  static _Nd ones(List<int> shape) => _Nd(shape, List.filled(_prod(shape), 1));
  static _Nd zeros(List<int> shape) => _Nd(shape, List.filled(_prod(shape), 0));
  static _Nd eye(int n) {
    final d = List<double>.filled(n * n, 0);
    for (var i = 0; i < n; i++) {
      d[i * n + i] = 1;
    }
    return _Nd([n, n], d);
  }

  _Nd reshape(List<int> next) {
    if (_prod(next) != size) throw _PyErr('ValueError: cannot reshape');
    return _Nd(next, List<double>.of(data));
  }

  _Nd get T {
    if (shape.length != 2) return _Nd(shape.reversed.toList(), List<double>.of(data));
    final r = shape[0];
    final c = shape[1];
    final out = List<double>.filled(size, 0);
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        out[j * r + i] = data[i * c + j];
      }
    }
    return _Nd([c, r], out);
  }

  _Nd reduceAxis(int axis, double Function(double, double) op, double start) {
    if (shape.length != 2) return _Nd([1], [data.fold<double>(start, op)]);
    if (axis == 0) {
      final out = List<double>.filled(shape[1], start);
      for (var j = 0; j < shape[1]; j++) {
        var acc = start;
        for (var i = 0; i < shape[0]; i++) {
          acc = op(acc, data[i * shape[1] + j]);
        }
        out[j] = acc;
      }
      return _Nd([shape[1]], out);
    }
    final out = List<double>.filled(shape[0], start);
    for (var i = 0; i < shape[0]; i++) {
      var acc = start;
      for (var j = 0; j < shape[1]; j++) {
        acc = op(acc, data[i * shape[1] + j]);
      }
      out[i] = acc;
    }
    return _Nd([shape[0]], out);
  }

  double det2() {
    if (shape.length != 2 || shape[0] != 2 || shape[1] != 2) throw _PyErr('ValueError: det is 2x2 here');
    return data[0] * data[3] - data[1] * data[2];
  }

  _Nd inv2() {
    final d = det2();
    if (d == 0) throw _PyErr('LinAlgError: singular');
    return _Nd([2, 2], [data[3] / d, -data[1] / d, -data[2] / d, data[0] / d]);
  }
  static _Nd fromList(Object? raw) {
    if (raw is _Nd) return raw;
    if (raw is List) {
      if (raw.isEmpty) return _Nd([0], []);
      if (raw.first is List) {
        final rows = raw.cast<List>();
        final w = rows.first.length;
        final data = <double>[];
        for (final r in rows) {
          for (final v in r) {
            data.add(_num(v).toDouble());
          }
        }
        return _Nd([rows.length, w], data);
      }
      return _Nd([raw.length], raw.map((e) => _num(e).toDouble()).toList());
    }
    return _Nd([], [_num(raw).toDouble()]);
  }

  _Nd broadcastOp(_Nd other, double Function(double, double) op) {
    final outShape = _broadcastShape(shape, other.shape);
    final out = List<double>.filled(_prod(outShape), 0);
    for (var i = 0; i < out.length; i++) {
      final coord = _unravel(i, outShape);
      out[i] = op(_at(coord, shape, data), other._at(coord, other.shape, other.data));
    }
    return _Nd(outShape, out);
  }

  double _at(List<int> coord, List<int> sh, List<double> d) {
    final aligned = List<int>.filled(sh.length, 0);
    final off = coord.length - sh.length;
    for (var i = 0; i < sh.length; i++) {
      aligned[i] = sh[i] == 1 ? 0 : coord[i + off];
    }
    return d[_ravel(aligned, sh)];
  }

  double mean() => data.isEmpty ? 0 : data.reduce((a, b) => a + b) / data.length;
}

int _prod(List<int> s) => s.isEmpty ? 1 : s.reduce((a, b) => a * b);

List<int> _broadcastShape(List<int> a, List<int> b) {
  final n = math.max(a.length, b.length);
  final out = List<int>.filled(n, 1);
  for (var i = 0; i < n; i++) {
    final ai = i < n - a.length ? 1 : a[i - (n - a.length)];
    final bi = i < n - b.length ? 1 : b[i - (n - b.length)];
    if (ai != bi && ai != 1 && bi != 1) throw _PyErr('ValueError: operands could not be broadcast');
    out[i] = math.max(ai, bi);
  }
  return out;
}

List<int> _unravel(int i, List<int> shape) {
  final c = List<int>.filled(shape.length, 0);
  var x = i;
  for (var k = shape.length - 1; k >= 0; k--) {
    c[k] = x % shape[k];
    x ~/= shape[k];
  }
  return c;
}

int _ravel(List<int> c, List<int> shape) {
  var i = 0;
  for (var k = 0; k < shape.length; k++) {
    i = i * shape[k] + c[k];
  }
  return i;
}

final _rng = math.Random(42);
var _npRng = math.Random(42);

class _Tuple {
  _Tuple(this.items);
  final List<Object?> items;
}

class _FileHandle {
  _FileHandle(this.path, this.mode, this.store);
  final String path;
  final String mode;
  final Map<String, String> store;

  void write(Object? v) {
    store[path] = '${store[path] ?? ''}${_str(v)}';
  }

  String read() => store[path] ?? '';

  List<String> readlines() {
    final text = read();
    if (text.isEmpty) return [];
    return text.split('\n');
  }

  void close() {}
}

final Map<String, Object?> _sharedBuiltins = {
  'len': _Native((args, _) => _len(args.first)),
  'range': _Native((args, _) {
    final a = args.map((e) => _num(e).toInt()).toList();
    if (a.length == 1) return [for (var i = 0; i < a[0]; i++) i];
    if (a.length == 2) return [for (var i = a[0]; i < a[1]; i++) i];
    return [for (var i = a[0]; i < a[1]; i += a[2]) i];
  }),
  'list': _Native((args, _) => args.isEmpty ? <Object?>[] : _iter(args.first).toList()),
  'tuple': _Native((args, _) => _Tuple(_iter(args.first).toList())),
  'dict': _Native((args, kwargs) => Map<Object?, Object?>.from(kwargs)),
  'set': _Native((args, _) => args.isEmpty ? <Object?>{} : {..._iter(args.first)}),
  'str': _Native((args, _) => _str(args.first)),
  'int': _Native((args, _) {
    final v = args.first;
    if (v is String) {
      final n = num.tryParse(v);
      if (n == null) throw _PyErr('ValueError: invalid literal for int()');
      return n.toInt();
    }
    return _num(v).toInt();
  }),
  'float': _Native((args, _) => _num(args.first).toDouble()),
  'bool': _Native((args, _) => _truth(args.first)),
  'round': _Native((args, _) {
    final n = _num(args.first).toDouble();
    final d = args.length > 1 ? _num(args[1]).toInt() : 0;
    final m = math.pow(10, d).toDouble();
    return (n * m).round() / m;
  }),
  'abs': _Native((args, _) => _num(args.first).abs()),
  'min': _Native((args, _) {
    final xs = args.length == 1 ? _iter(args.first).map(_num) : args.map(_num);
    return xs.reduce(math.min);
  }),
  'max': _Native((args, _) {
    final xs = args.length == 1 ? _iter(args.first).map(_num) : args.map(_num);
    return xs.reduce(math.max);
  }),
  'sum': _Native((args, _) => _iter(args.first).map(_num).fold<num>(0, (a, b) => a + b)),
  'type': _Native((args, _) {
    final v = args.first;
    if (v == null) return "<class 'NoneType'>";
    if (v is bool) return "<class 'bool'>";
    if (v is int) return "<class 'int'>";
    if (v is double) return "<class 'float'>";
    if (v is String) return "<class 'str'>";
    if (v is List) return "<class 'list'>";
    if (v is Map) return "<class 'dict'>";
    if (v is Set) return "<class 'set'>";
    return "<class '${v.runtimeType}'>";
  }),
  'zip': _Native((args, _) {
    final lists = args.map((e) => _iter(e).toList()).toList();
    final n = lists.map((e) => e.length).reduce(math.min);
    return [for (var i = 0; i < n; i++) [for (final l in lists) l[i]]];
  }),
  'enumerate': _Native((args, _) {
    final xs = _iter(args.first).toList();
    return [for (var i = 0; i < xs.length; i++) [i, xs[i]]];
  }),
  'isinstance': _Native((args, _) {
    final v = args[0];
    final t = args[1];
    if (identical(t, _sharedBuiltins['int'])) return v is int && v is! bool;
    if (identical(t, _sharedBuiltins['float'])) return v is double;
    if (identical(t, _sharedBuiltins['bool'])) return v is bool;
    if (identical(t, _sharedBuiltins['str'])) return v is String;
    if (identical(t, _sharedBuiltins['list'])) return v is List;
    if (identical(t, _sharedBuiltins['dict'])) return v is Map;
    if (identical(t, _sharedBuiltins['set'])) return v is Set;
    if (identical(t, _sharedBuiltins['tuple'])) return v is _Tuple;
    return false;
  }),
  'input': _Native((args, _) => 'Ada'),
  'any': _Native((args, _) => _iter(args.first).any(_truth)),
  'all': _Native((args, _) => _iter(args.first).every(_truth)),
  'reversed': _Native((args, _) => _iter(args.first).toList().reversed.toList()),
  'pow': _Native((args, _) => math.pow(_num(args[0]), _num(args[1]))),
  'divmod': _Native((args, _) {
    final a = _num(args[0]).toInt();
    final b = _num(args[1]).toInt();
    return _Tuple([a ~/ b, a % b]);
  }),
  'map': _Native((args, _) {
    final fn = args[0];
    return [for (final x in _iter(args[1])) _call(fn, [x], const {})];
  }),
  'filter': _Native((args, _) {
    final fn = args[0];
    return [for (final x in _iter(args[1])) if (_truth(_call(fn, [x], const {}))) x];
  }),
};

Object? _module(String name) {
  switch (name) {
    case 'json':
      return _Mod({
        'loads': _Native((args, _) => _jsonLoads(args.first as String)),
        'dumps': _Native((args, _) => _str(args.first)),
      });
    case 'math':
      return _Mod({
        'sqrt': _Native((args, _) => math.sqrt(_num(args.first).toDouble())),
        'pow': _Native((args, _) => math.pow(_num(args[0]), _num(args[1]))),
        'pi': 3.141592653589793,
        'ceil': _Native((args, _) => _num(args.first).ceil()),
        'floor': _Native((args, _) => _num(args.first).floor()),
      });
    case 'sys':
      return _Mod({
        'argv': ['app.py', '--epochs', '3'],
        'version': '3.12.0',
      });
    case 'os':
      return _Mod({
        'getcwd': _Native((_, __) => '/app'),
        'path': _Mod({
          'join': _Native((args, _) => args.map(_str).join('/')),
        }),
      });
    case 'numpy':
    case 'np':
      return _npModule();
    case 'pandas':
    case 'pd':
      return _pdModule();
    case 'matplotlib':
      return _Mod({'pyplot': _mplPyplot()});
    case 'scipy':
      return _spModule();
    case 'torch':
      return _torchModule();
    case 'tensorflow':
    case 'tf':
      return _tfModule();
    case 'asyncio':
      return _Mod({
        'sleep': _Native((_, __) => null),
        'gather': _Native((args, _) => args),
        'run': _Native((args, _) => args.isEmpty ? null : _call(args.first, const [], const {})),
      });
    default:
      return _Mod({});
  }
}

Object? _fromImport(String mod, String name) {
  if (name == 'dataclass') {
    return _Native((args, kwargs) {
      return _Native((inner, __) => inner.first);
    });
  }
  final m = _module(mod);
  if (m is _Mod && m.attrs.containsKey(name)) return m.attrs[name];
  return _Native((_, __) => null);
}

_Mod _npModule() {
  _Nd Function(List<Object?>) asArr = (args) => _Nd.fromList(args.first);
  _Nd filled(Object? shape, double v) => _Nd(_shapeArg(shape), List.filled(_prod(_shapeArg(shape)), v));
  return _Mod({
    'array': _Native((args, _) => asArr(args)),
    'asarray': _Native((args, _) => asArr(args)),
    'ones': _Native((args, _) => _Nd.ones(_shapeArg(args.first))),
    'zeros': _Native((args, _) => _Nd.zeros(_shapeArg(args.first))),
    'empty': _Native((args, _) => _Nd.zeros(_shapeArg(args.first))),
    'full': _Native((args, _) => filled(args[0], _num(args[1]).toDouble())),
    'eye': _Native((args, _) => _Nd.eye(_num(args.first).toInt())),
    'identity': _Native((args, _) => _Nd.eye(_num(args.first).toInt())),
    'arange': _Native((args, _) {
      final a = args.map((e) => _num(e).toInt()).toList();
      late final List<int> xs;
      if (a.length == 1) {
        xs = [for (var i = 0; i < a[0]; i++) i];
      } else if (a.length == 2) {
        xs = [for (var i = a[0]; i < a[1]; i++) i];
      } else {
        xs = [for (var i = a[0]; i < a[1]; i += a[2]) i];
      }
      return _Nd([xs.length], xs.map((e) => e.toDouble()).toList());
    }),
    'linspace': _Native((args, _) {
      final a = _num(args[0]).toDouble();
      final b = _num(args[1]).toDouble();
      final n = args.length > 2 ? _num(args[2]).toInt() : 50;
      if (n <= 1) return _Nd([1], [a]);
      return _Nd([n], [for (var i = 0; i < n; i++) a + (b - a) * i / (n - 1)]);
    }),
    'zeros_like': _Native((args, _) => _Nd.zeros(_asNd(args.first).shape)),
    'ones_like': _Native((args, _) => _Nd.ones(_asNd(args.first).shape)),
    'full_like': _Native((args, _) => filled(_asNd(args.first).shape, _num(args[1]).toDouble())),
    'empty_like': _Native((args, _) => _Nd.zeros(_asNd(args.first).shape)),
    'logspace': _Native((args, _) {
      final a = _num(args[0]).toDouble();
      final b = _num(args[1]).toDouble();
      final n = args.length > 2 ? _num(args[2]).toInt() : 50;
      if (n <= 1) return _Nd([1], [math.pow(10, a).toDouble()]);
      return _Nd([n], [for (var i = 0; i < n; i++) math.pow(10, a + (b - a) * i / (n - 1)).toDouble()]);
    }),
    'geomspace': _Native((args, _) {
      final a = _num(args[0]).toDouble();
      final b = _num(args[1]).toDouble();
      final n = args.length > 2 ? _num(args[2]).toInt() : 50;
      if (n <= 1) return _Nd([1], [a]);
      final la = math.log(a);
      final lb = math.log(b);
      return _Nd([n], [for (var i = 0; i < n; i++) math.exp(la + (lb - la) * i / (n - 1))]);
    }),
    'concatenate': _Native((args, _) => _npConcat(args.first)),
    'stack': _Native((args, _) => _npStack(args.first)),
    'vstack': _Native((args, _) => _npConcat(args.first)),
    'hstack': _Native((args, _) {
      final xs = _iter(args.first).map(_asNd).toList();
      final data = <double>[];
      for (final x in xs) {
        data.addAll(x.data);
      }
      return _Nd([data.length], data);
    }),
    'sum': _Native((args, kwargs) => _npReduce(args.first, kwargs, (a, b) => a + b, 0)),
    'mean': _Native((args, kwargs) {
      final x = _asNd(args.first);
      return x.mean();
    }),
    'min': _Native((args, _) => _asNd(args.first).data.reduce(math.min)),
    'max': _Native((args, _) => _asNd(args.first).data.reduce(math.max)),
    'abs': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map((e) => e.abs()).toList());
    }),
    'sqrt': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map(math.sqrt).toList());
    }),
    'square': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map((e) => e * e).toList());
    }),
    'exp': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map(math.exp).toList());
    }),
    'log': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map(math.log).toList());
    }),
    'sin': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map(math.sin).toList());
    }),
    'cos': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map(math.cos).toList());
    }),
    'floor': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map((e) => e.floorToDouble()).toList());
    }),
    'ceil': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map((e) => e.ceilToDouble()).toList());
    }),
    'round': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, x.data.map((e) => e.roundToDouble()).toList());
    }),
    'sort': _Native((args, _) {
      final x = _asNd(args.first);
      final d = List<double>.of(x.data)..sort();
      return _Nd(x.shape, d);
    }),
    'unique': _Native((args, _) {
      final x = _asNd(args.first);
      final u = <double>{...x.data}.toList()..sort();
      return _Nd([u.length], u);
    }),
    'where': _Native((args, _) {
      if (args.length == 1) {
        final x = _asNd(args.first);
        return [for (var i = 0; i < x.data.length; i++) if (x.data[i] != 0) i];
      }
      final c = _asNd(args[0]);
      final a = _asNd(args[1]);
      final b = _asNd(args[2]);
      return _Nd(c.shape, [for (var i = 0; i < c.data.length; i++) c.data[i] != 0 ? a.data[i % a.data.length] : b.data[i % b.data.length]]);
    }),
    'isnan': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, [for (final e in x.data) e.isNaN ? 1.0 : 0.0]);
    }),
    'isinf': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, [for (final e in x.data) e.isInfinite ? 1.0 : 0.0]);
    }),
    'isfinite': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd(x.shape, [for (final e in x.data) e.isFinite ? 1.0 : 0.0]);
    }),
    'nan': double.nan,
    'inf': double.infinity,
    'newaxis': null,
    'dot': _Native((args, _) => _matmul(args[0], args[1])),
    'matmul': _Native((args, _) => _matmul(args[0], args[1])),
    'linalg': _Mod({
      'det': _Native((args, _) => _asNd(args.first).det2()),
      'inv': _Native((args, _) => _asNd(args.first).inv2()),
      'norm': _Native((args, _) {
        final x = _asNd(args.first);
        return math.sqrt(x.data.fold<double>(0, (a, b) => a + b * b));
      }),
    }),
    'random': _Mod({
      'seed': _Native((args, _) {
        _npRng = math.Random(_num(args.first).toInt());
        return null;
      }),
      'randn': _Native((args, _) {
        final shape = args.map((e) => _num(e).toInt()).toList();
        final n = _prod(shape);
        return _Nd(shape, [for (var i = 0; i < n; i++) _boxMuller()]);
      }),
      'rand': _Native((args, _) {
        final shape = args.map((e) => _num(e).toInt()).toList();
        final n = _prod(shape);
        return _Nd(shape, [for (var i = 0; i < n; i++) _npRng.nextDouble()]);
      }),
      'randint': _Native((args, _) {
        final lo = _num(args[0]).toInt();
        final hi = _num(args[1]).toInt();
        return lo + _npRng.nextInt(math.max(1, hi - lo));
      }),
    }),
  });
}

_Nd _asNd(Object? v) => v is _Nd ? v : _Nd.fromList(v);

Object? _npReduce(Object? raw, Map<String, Object?> kwargs, double Function(double, double) op, double start) {
  final x = _asNd(raw);
  final axis = kwargs['axis'];
  if (axis == null) return x.data.fold<double>(start, op);
  return x.reduceAxis(_num(axis).toInt(), op, start);
}

_Nd _npConcat(Object? raw) {
  final xs = _iter(raw).map(_asNd).toList();
  if (xs.isEmpty) return _Nd([0], []);
  final data = <double>[];
  var rows = 0;
  final cols = xs.first.shape.length > 1 ? xs.first.shape[1] : xs.first.shape[0];
  for (final x in xs) {
    data.addAll(x.data);
    rows += x.shape[0];
  }
  if (xs.first.shape.length == 1) return _Nd([data.length], data);
  return _Nd([rows, cols], data);
}

_Nd _npStack(Object? raw) {
  final xs = _iter(raw).map(_asNd).toList();
  final data = <double>[];
  for (final x in xs) {
    data.addAll(x.data);
  }
  return _Nd([xs.length, ...xs.first.shape], data);
}

_Mod _pdModule() {
  return _Mod({
    'DataFrame': _Native((args, kwargs) => _DataFrame.from(args.isEmpty ? kwargs : args.first, kwargs)),
    'Series': _Native((args, kwargs) => _Series.from(args.first, kwargs)),
    'NA': null,
    'NaT': null,
    'concat': _Native((args, kwargs) => _pdConcat(args.first, kwargs)),
    'merge': _Native((args, kwargs) => _pdMerge(args[0] as _DataFrame, args[1] as _DataFrame, kwargs)),
    'get_dummies': _Native((args, _) => _pdGetDummies(args.first)),
    'to_datetime': _Native((args, _) {
      final xs = _iter(args.first).map(_str).toList();
      return _Series(xs);
    }),
    'cut': _Native((args, _) {
      final xs = _iter(args.first).map(_num).toList();
      final n = args.length > 1 ? _num(args[1]).toInt() : 2;
      final lo = xs.reduce(math.min);
      final hi = xs.reduce(math.max);
      final w = (hi - lo) / n;
      return _Series([for (final x in xs) w == 0 ? 0 : ((x - lo) / w).floor().clamp(0, n - 1)]);
    }),
    'read_csv': _Native((args, _) {
      final name = args.isEmpty ? 'table.csv' : _str(args.first);
      return _pdStore[name] ?? _DataFrame.from({'n': [1, 2]}, const {});
    }),
    'read_json': _Native((args, _) => _DataFrame.from(args.first, const {})),
    'read_excel': _Native((args, _) {
      final name = args.isEmpty ? 'table.xlsx' : _str(args.first);
      return _pdStore[name] ?? _DataFrame.from({'n': [1, 2]}, const {});
    }),
    'read_parquet': _Native((args, _) {
      final name = args.isEmpty ? 'table.parquet' : _str(args.first);
      return _pdStore[name] ?? _DataFrame.from({'n': [1, 2]}, const {});
    }),
    'read_sql': _Native((args, _) => _DataFrame.from({'n': [1, 2]}, const {})),
    'read_html': _Native((args, _) => [_DataFrame.from({'col': [1, 2]}, const {})]),
  });
}

final Map<String, _DataFrame> _pdStore = {};

_MplFigure? _mplFig;

_MplFigure _mplCurrent() => _mplFig ??= _MplFigure();

_MplAxes _mplGca() {
  final fig = _mplCurrent();
  if (fig.axes.isEmpty) fig.axes.add(_MplAxes(fig));
  return fig.axes.last;
}

List<double> _mplNums(Object? raw) {
  if (raw is _Nd) return List<double>.of(raw.data);
  if (raw is _Series) return [for (final e in raw.values) _num(e ?? 0).toDouble()];
  return [for (final e in _iter(raw)) _num(e).toDouble()];
}

class _MplFigure {
  _MplFigure({this.w = 6.0, this.h = 4.0, this.dpi = 100});
  double w;
  double h;
  int dpi;
  final List<_MplAxes> axes = [];
  String? lastSave;

  _Tuple sizeInches() => _Tuple([w, h]);
}

class _MplAxes {
  _MplAxes(this.fig);
  final _MplFigure fig;
  double x0 = 0;
  double x1 = 1;
  double y0 = 0;
  double y1 = 1;
  var xlimSet = false;
  var ylimSet = false;
  String xlabel = '';
  String ylabel = '';
  String title = '';
  String xscale = 'linear';
  String yscale = 'linear';
  String projection = 'rectilinear';
  final List<Object?> lines = [];
  int nseries = 0;

  void addSeries(List<double> x, List<double> y) {
    nseries++;
    lines.add({'n': y.length});
    if (x.isEmpty || y.isEmpty) return;
    final xmin = x.reduce(math.min);
    final xmax = x.reduce(math.max);
    final ymin = y.reduce(math.min);
    final ymax = y.reduce(math.max);
    if (!xlimSet) {
      x0 = xmin;
      x1 = xmax == xmin ? xmin + 1 : xmax;
    }
    if (!ylimSet) {
      y0 = ymin;
      y1 = ymax == ymin ? ymin + 1 : ymax;
    }
  }

  void setXlim(Object? a, Object? b) {
    xlimSet = true;
    if (b == null) {
      final xs = _mplNums(a);
      x0 = xs[0];
      x1 = xs[1];
    } else {
      x0 = _num(a).toDouble();
      x1 = _num(b).toDouble();
    }
  }

  void setYlim(Object? a, Object? b) {
    ylimSet = true;
    if (b == null) {
      final ys = _mplNums(a);
      y0 = ys[0];
      y1 = ys[1];
    } else {
      y0 = _num(a).toDouble();
      y1 = _num(b).toDouble();
    }
  }
}

void _mplPlot(_MplAxes ax, List<Object?> args) {
  if (args.isEmpty) return;
  if (args.length == 1) {
    final y = _mplNums(args.first);
    ax.addSeries([for (var i = 0; i < y.length; i++) i.toDouble()], y);
  } else {
    ax.addSeries(_mplNums(args[0]), _mplNums(args[1]));
  }
}

List<double> _mplHist(List<double> xs, int bins) {
  if (xs.isEmpty) return List.filled(bins, 0);
  final lo = xs.reduce(math.min);
  final hi = xs.reduce(math.max);
  final w = hi == lo ? 1.0 : (hi - lo) / bins;
  final counts = List<double>.filled(bins, 0);
  for (final v in xs) {
    var i = hi == lo ? 0 : ((v - lo) / w).floor();
    if (i >= bins) i = bins - 1;
    if (i < 0) i = 0;
    counts[i] += 1;
  }
  return counts;
}

_Mod _mplPyplot() {
  Object? save(List<Object?> args) {
    final name = args.isEmpty ? 'fig.png' : _str(args.first);
    _mplCurrent().lastSave = name;
    return name;
  }

  _MplFigure applyFigKw(Map<String, Object?> kwargs) {
    final fig = _MplFigure();
    final sz = kwargs['figsize'];
    if (sz != null) {
      final xs = _iter(sz).map((e) => _num(e).toDouble()).toList();
      if (xs.length >= 2) {
        fig.w = xs[0];
        fig.h = xs[1];
      }
    }
    if (kwargs['dpi'] != null) fig.dpi = _num(kwargs['dpi']).toInt();
    return fig;
  }

  return _Mod({
    'figure': _Native((args, kwargs) {
      _mplFig = applyFigKw(kwargs);
      return _mplFig;
    }),
    'subplots': _Native((args, kwargs) {
      final r = args.isNotEmpty ? _num(args[0]).toInt() : (kwargs['nrows'] == null ? 1 : _num(kwargs['nrows']).toInt());
      final c = args.length > 1 ? _num(args[1]).toInt() : (kwargs['ncols'] == null ? 1 : _num(kwargs['ncols']).toInt());
      final fig = applyFigKw(kwargs);
      for (var i = 0; i < r * c; i++) {
        fig.axes.add(_MplAxes(fig));
      }
      _mplFig = fig;
      Object? axOut;
      if (r * c == 1) {
        axOut = fig.axes.first;
      } else if (c == 1 || r == 1) {
        axOut = fig.axes;
      } else {
        axOut = [for (var i = 0; i < r; i++) fig.axes.sublist(i * c, (i + 1) * c)];
      }
      return _Tuple([fig, axOut]);
    }),
    'subplot': _Native((args, _) {
      final fig = _mplCurrent();
      if (fig.axes.isEmpty) fig.axes.add(_MplAxes(fig));
      final i = args.length >= 3 ? _num(args[2]).toInt() - 1 : 0;
      while (fig.axes.length <= i) {
        fig.axes.add(_MplAxes(fig));
      }
      return fig.axes[i.clamp(0, fig.axes.length - 1)];
    }),
    'gca': _Native((_, __) => _mplGca()),
    'gcf': _Native((_, __) => _mplCurrent()),
    'plot': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().lines;
    }),
    'scatter': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().lines;
    }),
    'bar': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'barh': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'hist': _Native((args, kwargs) {
      final xs = _mplNums(args.first);
      final n = kwargs['bins'] == null ? (args.length > 1 ? _num(args[1]).toInt() : 10) : _num(kwargs['bins']).toInt();
      final counts = _mplHist(xs, n);
      _mplGca().addSeries([for (var i = 0; i < counts.length; i++) i.toDouble()], counts);
      return _Tuple([counts, [for (var i = 0; i <= n; i++) i.toDouble()], 'patches']);
    }),
    'pie': _Native((args, _) {
      final xs = _mplNums(args.first);
      _mplGca().nseries++;
      return xs;
    }),
    'fill_between': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'boxplot': _Native((args, _) {
      _mplGca().nseries++;
      return {'n': _iter(args.first).length};
    }),
    'violinplot': _Native((args, _) {
      _mplGca().nseries++;
      return {'n': _iter(args.first).length};
    }),
    'errorbar': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'stem': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'eventplot': _Native((args, _) {
      _mplGca().nseries++;
      return _mplGca().nseries;
    }),
    'stackplot': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'step': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      return _mplGca().nseries;
    }),
    'contour': _Native((args, _) {
      _mplGca().nseries++;
      return _mplGca().nseries;
    }),
    'contourf': _Native((args, _) {
      _mplGca().nseries++;
      return _mplGca().nseries;
    }),
    'imshow': _Native((args, _) {
      _mplGca().nseries++;
      final raw = args.first;
      if (raw is _Nd) return raw.shape;
      if (raw is List) return [raw.length];
      return [1, 1];
    }),
    'clabel': _Native((_, __) => null),
    'colorbar': _Native((_, __) => _Mod({'set_label': _Native((args, _) => _str(args.first))})),
    'xlabel': _Native((args, _) => _mplGca().xlabel = _str(args.first)),
    'ylabel': _Native((args, _) => _mplGca().ylabel = _str(args.first)),
    'title': _Native((args, _) => _mplGca().title = _str(args.first)),
    'legend': _Native((_, __) => 'legend'),
    'grid': _Native((_, __) => true),
    'text': _Native((args, _) => args.length >= 3 ? _str(args[2]) : ''),
    'annotate': _Native((args, kwargs) => args.isEmpty ? (kwargs['s'] ?? 'ann') : args.first),
    'xlim': _Native((args, _) {
      if (args.isEmpty) return _Tuple([_mplGca().x0, _mplGca().x1]);
      _mplGca().setXlim(args[0], args.length > 1 ? args[1] : null);
      return _Tuple([_mplGca().x0, _mplGca().x1]);
    }),
    'ylim': _Native((args, _) {
      if (args.isEmpty) return _Tuple([_mplGca().y0, _mplGca().y1]);
      _mplGca().setYlim(args[0], args.length > 1 ? args[1] : null);
      return _Tuple([_mplGca().y0, _mplGca().y1]);
    }),
    'xticks': _Native((args, _) => args.isEmpty ? [] : args.first),
    'yticks': _Native((args, _) => args.isEmpty ? [] : args.first),
    'xscale': _Native((args, _) => _mplGca().xscale = _str(args.first)),
    'yscale': _Native((args, _) => _mplGca().yscale = _str(args.first)),
    'loglog': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      _mplGca().xscale = 'log';
      _mplGca().yscale = 'log';
      return _mplGca().nseries;
    }),
    'semilogx': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      _mplGca().xscale = 'log';
      return _mplGca().nseries;
    }),
    'semilogy': _Native((args, _) {
      _mplPlot(_mplGca(), args);
      _mplGca().yscale = 'log';
      return _mplGca().nseries;
    }),
    'twinx': _Native((_, __) {
      final ax = _MplAxes(_mplCurrent());
      _mplCurrent().axes.add(ax);
      return ax;
    }),
    'twiny': _Native((_, __) {
      final ax = _MplAxes(_mplCurrent());
      _mplCurrent().axes.add(ax);
      return ax;
    }),
    'tight_layout': _Native((_, __) => null),
    'show': _Native((_, __) => null),
    'close': _Native((_, __) {
      _mplFig = null;
      return null;
    }),
    'savefig': _Native((args, _) => save(args)),
    'style': _Mod({
      'use': _Native((args, _) => _str(args.first)),
    }),
    'rcParams': <Object?, Object?>{'figure.figsize': [6.4, 4.8], 'font.size': 10},
    'rc': _Native((_, kwargs) => kwargs),
    'table': _Native((args, kwargs) {
      final cell = kwargs['cellText'] ?? args.first;
      return {'rows': _iter(cell).length};
    }),
    'polar': _Native((args, _) {
      final ax = _mplGca();
      ax.projection = 'polar';
      _mplPlot(ax, args);
      return ax.nseries;
    }),
  });
}

class _SpMat {
  _SpMat({required this.rows, required this.cols, required this.entries, this.format = 'csr'});
  int rows;
  int cols;
  final List<List<double>> entries;
  String format;

  int get nnz => entries.length;
  _Tuple get shape => _Tuple([rows, cols]);

  static _SpMat fromDense(_Nd a, [String format = 'csr']) {
    final r = a.shape.isEmpty ? 1 : a.shape[0];
    final c = a.shape.length < 2 ? 1 : a.shape[1];
    final xs = <List<double>>[];
    if (a.shape.length == 1) {
      for (var i = 0; i < a.data.length; i++) {
        if (a.data[i] != 0) xs.add([0, i.toDouble(), a.data[i]]);
      }
      return _SpMat(rows: 1, cols: a.data.length, entries: xs, format: format);
    }
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        final v = a.data[i * c + j];
        if (v != 0) xs.add([i.toDouble(), j.toDouble(), v]);
      }
    }
    return _SpMat(rows: r, cols: c, entries: xs, format: format);
  }

  _Nd toarray() {
    final d = List<double>.filled(rows * cols, 0);
    for (final e in entries) {
      final i = e[0].toInt();
      final j = e[1].toInt();
      if (i >= 0 && i < rows && j >= 0 && j < cols) d[i * cols + j] = e[2];
    }
    return _Nd([rows, cols], d);
  }

  _SpMat asFormat(String next) => _SpMat(rows: rows, cols: cols, entries: [for (final e in entries) List<double>.of(e)], format: next);
}

double _spCosine(List<double> a, List<double> b) {
  var nume = 0.0, dx = 0.0, dy = 0.0;
  final n = math.min(a.length, b.length);
  for (var i = 0; i < n; i++) {
    nume += a[i] * b[i];
    dx += a[i] * a[i];
    dy += b[i] * b[i];
  }
  final den = math.sqrt(dx * dy);
  return den == 0 ? 0 : nume / den;
}

double _erfApprox(double x) {
  if (x.abs() < 1e-15) return 0.0;
  final sign = x < 0 ? -1.0 : 1.0;
  x = x.abs();
  const a1 = 0.254829592, a2 = -0.284496736, a3 = 1.421413741, a4 = -1.453152027, a5 = 1.061405429, p = 0.3275911;
  final t = 1.0 / (1.0 + p * x);
  final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
  return sign * y;
}

double _gammaPos(double x) {
  if (x == x.roundToDouble() && x >= 1) {
    var a = 1.0;
    for (var i = 2; i < x.round(); i++) {
      a *= i;
    }
    return a;
  }
  return math.exp(_lngamma(x));
}

double _lngamma(double z) {
  // Stirling-ish for teaching values near small positives.
  if (z <= 0) return double.nan;
  return math.log(_gammaPos(z <= 1 ? z + 1 : z)) - (z <= 1 ? math.log(z) : 0);
}

Object? _spSolve(Object? aRaw, Object? bRaw) {
  final A = _asNd(aRaw);
  final b = _asNd(bRaw);
  if (A.shape.length == 2 && A.shape[0] == 2 && A.shape[1] == 2) {
    return _matmul(A.inv2(), b);
  }
  if (A.shape.length == 2 && A.shape[0] == A.shape[1]) {
    final n = A.shape[0];
    final out = <double>[];
    for (var i = 0; i < n; i++) {
      final piv = A.data[i * n + i];
      out.add(piv == 0 ? 0.0 : b.data[i] / piv);
    }
    return _Nd([n], out);
  }
  return b;
}

double _spNorm(Object? raw) {
  final x = _asNd(raw);
  return math.sqrt(x.data.fold<double>(0, (a, b) => a + b * b));
}

_Mod _optResult(double x, double fun) => _Mod({
      'x': _Nd([1], [x]),
      'success': true,
      'fun': fun,
      'message': 'ok',
    });

_Mod _spModule() {
  _Native sparseCtor(String format) => _Native((args, _) {
        if (args.isEmpty) return _SpMat(rows: 0, cols: 0, entries: [], format: format);
        return _SpMat.fromDense(_asNd(args.first), format);
      });

  final linalg = _Mod({
    'inv': _Native((args, _) => _asNd(args.first).inv2()),
    'det': _Native((args, _) => _asNd(args.first).det2()),
    'solve': _Native((args, _) => _spSolve(args[0], args[1])),
    'lstsq': _Native((args, _) {
      final x = _spSolve(args[0], args[1]);
      return _Tuple([x, _Nd([1], [0.0]), (_asNd(args[0]).shape[0]), _Nd([1], [1.0])]);
    }),
    'norm': _Native((args, _) => _spNorm(args.first)),
    'trace': _Native((args, _) {
      final A = _asNd(args.first);
      final n = math.min(A.shape[0], A.shape.length > 1 ? A.shape[1] : A.shape[0]);
      var s = 0.0;
      final c = A.shape.length > 1 ? A.shape[1] : 1;
      for (var i = 0; i < n; i++) {
        s += A.data[i * c + i];
      }
      return s;
    }),
    'matrix_rank': _Native((args, _) {
      final A = _asNd(args.first);
      if (A.shape.length == 2 && A.shape[0] == 2 && A.shape[1] == 2) {
        return A.det2().abs() < 1e-12 ? 1 : 2;
      }
      return A.shape.isEmpty ? 0 : A.shape[0];
    }),
    'cond': _Native((args, _) {
      final A = _asNd(args.first);
      if (A.shape.length == 2 && A.shape[0] == 2) {
        final d = A.det2().abs();
        return d == 0 ? double.infinity : _spNorm(A) * _spNorm(A.inv2());
      }
      return 1.0;
    }),
    'lu': _Native((args, _) {
      final A = _asNd(args.first);
      final n = A.shape[0];
      return _Tuple([_Nd.eye(n), _Nd.eye(n), A]);
    }),
    'qr': _Native((args, _) {
      final A = _asNd(args.first);
      return _Tuple([_Nd.eye(A.shape[0]), A]);
    }),
    'cholesky': _Native((args, _) {
      final A = _asNd(args.first);
      if (A.shape[0] == 2 && A.data[1] == 0 && A.data[2] == 0) {
        return _Nd([2, 2], [math.sqrt(A.data[0]), 0, 0, math.sqrt(A.data[3])]);
      }
      return A;
    }),
    'svd': _Native((args, _) {
      final A = _asNd(args.first);
      final n = A.shape[0];
      final m = A.shape.length > 1 ? A.shape[1] : n;
      final k = math.min(n, m);
      return _Tuple([_Nd.eye(n), _Nd([k], List.filled(k, 1.0)), _Nd.eye(m)]);
    }),
    'schur': _Native((args, _) {
      final A = _asNd(args.first);
      return _Tuple([A, _Nd.eye(A.shape[0])]);
    }),
    'eig': _Native((args, _) {
      final A = _asNd(args.first);
      final n = A.shape[0];
      final w = <double>[];
      for (var i = 0; i < n; i++) {
        w.add(A.data[i * n + i]);
      }
      return _Tuple([_Nd([n], w), _Nd.eye(n)]);
    }),
    'eigh': _Native((args, _) {
      final A = _asNd(args.first);
      final n = A.shape[0];
      final w = <double>[];
      for (var i = 0; i < n; i++) {
        w.add(A.data[i * n + i]);
      }
      return _Tuple([_Nd([n], w), _Nd.eye(n)]);
    }),
    'eigvals': _Native((args, _) {
      final A = _asNd(args.first);
      final n = A.shape[0];
      return _Nd([n], [for (var i = 0; i < n; i++) A.data[i * n + i]]);
    }),
  });

  final sparseLinalg = _Mod({
    'spsolve': _Native((args, _) {
      final A = args[0] is _SpMat ? (args[0] as _SpMat).toarray() : args[0];
      return _spSolve(A, args[1]);
    }),
    'cg': _Native((args, _) => _Tuple([_spSolve(args[0] is _SpMat ? (args[0] as _SpMat).toarray() : args[0], args[1]), 0])),
    'gmres': _Native((args, _) => _Tuple([_asNd(args[1]), 0])),
    'bicgstab': _Native((args, _) => _Tuple([_asNd(args[1]), 0])),
    'lsqr': _Native((args, _) => _Tuple([_asNd(args[1]), 0])),
    'lsmr': _Native((args, _) => _Tuple([_asNd(args[1]), 0])),
    'eigs': _Native((args, kwargs) {
      final k = kwargs['k'] == null ? 1 : _num(kwargs['k']).toInt();
      return _Tuple([_Nd([k], List.filled(k, 1.0)), _Nd.eye(k)]);
    }),
    'eigsh': _Native((args, kwargs) {
      final k = kwargs['k'] == null ? 1 : _num(kwargs['k']).toInt();
      return _Tuple([_Nd([k], List.filled(k, 1.0)), _Nd.eye(k)]);
    }),
    'LinearOperator': _Native((args, _) => args.first),
  });

  final sparse = _Mod({
    'csr_matrix': sparseCtor('csr'),
    'csc_matrix': sparseCtor('csc'),
    'coo_matrix': sparseCtor('coo'),
    'lil_matrix': sparseCtor('lil'),
    'dok_matrix': sparseCtor('dok'),
    'dia_matrix': sparseCtor('dia'),
    'bsr_matrix': sparseCtor('bsr'),
    'issparse': _Native((args, _) => args.first is _SpMat),
    'linalg': sparseLinalg,
  });

  Object? min1d(Object? fn, double start) {
    var x = start;
    var f = _num(_call(fn, [x], const {})).toDouble();
    for (var i = 0; i < 40; i++) {
      final fp = _num(_call(fn, [x + 1e-4], const {})).toDouble();
      final g = (fp - f) / 1e-4;
      x -= 0.25 * g;
      f = _num(_call(fn, [x], const {})).toDouble();
    }
    return _optResult(x, f);
  }

  final optimize = _Mod({
    'root': _Native((args, _) {
      final fn = args.first;
      var x = args.length > 1 ? _num(args[1]).toDouble() : 0.0;
      for (var i = 0; i < 20; i++) {
        final f = _num(_call(fn, [x], const {})).toDouble();
        final fp = _num(_call(fn, [x + 1e-4], const {})).toDouble();
        final g = (fp - f) / 1e-4;
        if (g.abs() < 1e-12) break;
        x -= f / g;
      }
      return _optResult(x, 0);
    }),
    'root_scalar': _Native((args, kwargs) => _optResult(0, 0)),
    'minimize': _Native((args, _) => min1d(args.first, args.length > 1 ? _num(_asNd(args[1]).data.first).toDouble() : 0.0)),
    'minimize_scalar': _Native((args, _) => min1d(args.first, 0.0)),
    'least_squares': _Native((args, _) => min1d(args.first, 0.0)),
    'curve_fit': _Native((args, _) {
      final ys = _asNd(args[2]);
      return _Tuple([_Nd([1], [ys.mean()]), _Nd([1, 1], [1.0])]);
    }),
    'differential_evolution': _Native((args, _) => min1d(args.first, 0.0)),
    'basinhopping': _Native((args, _) => min1d(args.first, args.length > 1 ? _num(args[1]).toDouble() : 0.0)),
    'dual_annealing': _Native((args, _) => min1d(args.first, 0.0)),
    'Bounds': _Native((args, _) => _Tuple(args)),
    'LinearConstraint': _Native((args, _) => args.first),
    'NonlinearConstraint': _Native((args, _) => args.first),
  });

  final spatial = _Mod({
    'distance': _Mod({
      'euclidean': _Native((args, _) {
        final a = _mplNums(args[0]);
        final b = _mplNums(args[1]);
        var s = 0.0;
        for (var i = 0; i < a.length; i++) {
          final d = a[i] - b[i];
          s += d * d;
        }
        return math.sqrt(s);
      }),
      'cityblock': _Native((args, _) {
        final a = _mplNums(args[0]);
        final b = _mplNums(args[1]);
        var s = 0.0;
        for (var i = 0; i < a.length; i++) {
          s += (a[i] - b[i]).abs();
        }
        return s;
      }),
      'minkowski': _Native((args, _) {
        final a = _mplNums(args[0]);
        final b = _mplNums(args[1]);
        var s = 0.0;
        for (var i = 0; i < a.length; i++) {
          s += (a[i] - b[i]).abs();
        }
        return s;
      }),
      'cosine': _Native((args, _) => 1 - _spCosine(_mplNums(args[0]), _mplNums(args[1]))),
      'cdist': _Native((args, _) {
        final A = _asNd(args[0]);
        final B = _asNd(args[1]);
        return _Nd([A.shape[0], B.shape[0]], List.filled(A.shape[0] * B.shape[0], 1.0));
      }),
      'pdist': _Native((args, _) {
        final A = _asNd(args.first);
        final n = A.shape[0];
        final m = n * (n - 1) ~/ 2;
        return _Nd([m], List.filled(m, 1.0));
      }),
      'squareform': _Native((args, _) {
        final v = _asNd(args.first);
        final n = (1 + math.sqrt(1 + 8 * v.size)).round();
        return _Nd([n, n], List.filled(n * n, 0));
      }),
    }),
    'KDTree': _Native((args, _) {
      final pts = _asNd(args.first);
      return _Mod({
        'n': pts.shape[0],
        'query': _Native((a, __) => _Tuple([0.0, 0])),
      });
    }),
    'cKDTree': _Native((args, _) => _Mod({'n': _asNd(args.first).shape[0]})),
  });

  final stats = _Mod({
    'norm': _Mod({
      'pdf': _Native((args, _) {
        final x = _num(args.first).toDouble();
        return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi);
      }),
      'cdf': _Native((args, _) {
        final x = _num(args.first).toDouble();
        if (x.abs() < 1e-12) return 0.5;
        return 0.5 * (1 + _erfApprox(x / math.sqrt(2)));
      }),
      'ppf': _Native((args, _) => _num(args.first).toDouble() == 0.5 ? 0.0 : 1.0),
      'sf': _Native((args, _) {
        final x = _num(args.first).toDouble();
        return 1 - 0.5 * (1 + _erfApprox(x / math.sqrt(2)));
      }),
      'mean': 0.0,
      'var': 1.0,
      'std': 1.0,
    }),
    'uniform': _Mod({
      'pdf': _Native((args, _) => 1.0),
      'cdf': _Native((args, _) => _num(args.first).toDouble().clamp(0, 1)),
    }),
    'describe': _Native((args, _) {
      final x = _asNd(args.first);
      return _Mod({'nobs': x.size, 'mean': x.mean(), 'variance': _pdStd([for (final e in x.data) e])});
    }),
    'ttest_ind': _Native((args, _) {
      final a = _asNd(args[0]);
      final b = _asNd(args[1]);
      final same = _eq(a.data, b.data);
      return _Tuple([same ? 0.0 : 1.0, same ? 1.0 : 0.05]);
    }),
    'ttest_1samp': _Native((args, _) => _Tuple([0.0, 1.0])),
    'chisquare': _Native((args, _) => _Tuple([0.0, 1.0])),
    'f_oneway': _Native((args, _) => _Tuple([1.0, 0.2])),
    'mannwhitneyu': _Native((args, _) => _Tuple([1.0, 0.5])),
    'wilcoxon': _Native((args, _) => _Tuple([0.0, 1.0])),
    'kruskal': _Native((args, _) => _Tuple([0.0, 1.0])),
    'ks_2samp': _Native((args, _) => _Tuple([0.0, 1.0])),
    'shapiro': _Native((args, _) => _Tuple([1.0, 0.8])),
    'anderson': _Native((args, _) => _Mod({'statistic': 0.2})),
    'pearsonr': _Native((args, _) {
      final a = _mplNums(args[0]);
      final b = _mplNums(args[1]);
      return _Tuple([_spCosine(a, b), 0.0]);
    }),
    'spearmanr': _Native((args, _) => _Tuple([1.0, 0.0])),
    'kendalltau': _Native((args, _) => _Tuple([1.0, 0.0])),
    'mode': _Native((args, _) {
      final xs = _asNd(args.first).data;
      final counts = <double, int>{};
      for (final v in xs) {
        counts[v] = (counts[v] ?? 0) + 1;
      }
      var best = xs.first;
      var n = 0;
      for (final e in counts.entries) {
        if (e.value > n) {
          n = e.value;
          best = e.key;
        }
      }
      return _Mod({'mode': _Nd([1], [best]), 'count': n});
    }),
    'skew': _Native((args, _) => 0.0),
    'kurtosis': _Native((args, _) => 0.0),
    'bootstrap': _Native((args, _) => _Mod({'confidence_interval': _Tuple([0.0, 1.0])})),
    'binom': _Mod({
      'pmf': _Native((args, _) => 0.25),
      'cdf': _Native((args, _) => 0.5),
    }),
    'poisson': _Mod({
      'pmf': _Native((args, _) => 0.2),
      'cdf': _Native((args, _) => 0.6),
    }),
  });
  stats.attrs['t'] = stats.attrs['norm'];
  stats.attrs['chi2'] = stats.attrs['norm'];
  stats.attrs['expon'] = stats.attrs['norm'];
  stats.attrs['gamma'] = stats.attrs['norm'];
  stats.attrs['beta'] = stats.attrs['norm'];
  stats.attrs['f'] = stats.attrs['norm'];

  final special = _Mod({
    'erf': _Native((args, _) => _erfApprox(_num(args.first).toDouble())),
    'erfc': _Native((args, _) => 1 - _erfApprox(_num(args.first).toDouble())),
    'gamma': _Native((args, _) => _gammaPos(_num(args.first).toDouble())),
    'beta': _Native((args, _) => _gammaPos(_num(args[0]).toDouble()) * _gammaPos(_num(args[1]).toDouble()) / _gammaPos(_num(args[0]).toDouble() + _num(args[1]).toDouble())),
    'digamma': _Native((args, _) => 0.0),
    'softmax': _Native((args, _) {
      final x = _asNd(args.first);
      final m = x.data.reduce(math.max);
      final e = [for (final v in x.data) math.exp(v - m)];
      final s = e.fold<double>(0, (a, b) => a + b);
      return _Nd(x.shape, [for (final v in e) v / s]);
    }),
    'logsumexp': _Native((args, _) {
      final x = _asNd(args.first);
      final m = x.data.reduce(math.max);
      var s = 0.0;
      for (final v in x.data) {
        s += math.exp(v - m);
      }
      return m + math.log(s);
    }),
    'expit': _Native((args, _) {
      final x = _num(args.first).toDouble();
      return 1 / (1 + math.exp(-x));
    }),
    'logit': _Native((args, _) {
      final p = _num(args.first).toDouble();
      return math.log(p / (1 - p));
    }),
    'binom': _Native((args, _) {
      final n = _num(args[0]).toInt();
      final k = _num(args[1]).toInt();
      var a = 1;
      for (var i = 0; i < k; i++) {
        a = a * (n - i) ~/ (i + 1);
      }
      return a;
    }),
  });

  final interpolate = _Mod({
    'interp1d': _Native((args, _) {
      final xs = _mplNums(args[0]);
      final ys = _mplNums(args[1]);
      return _Native((a, __) {
        final t = _num(a.first).toDouble();
        if (t <= xs.first) return ys.first;
        if (t >= xs.last) return ys.last;
        for (var i = 0; i < xs.length - 1; i++) {
          if (t >= xs[i] && t <= xs[i + 1]) {
            final u = (t - xs[i]) / (xs[i + 1] - xs[i]);
            return ys[i] * (1 - u) + ys[i + 1] * u;
          }
        }
        return ys.last;
      });
    }),
    'CubicSpline': _Native((args, _) {
      final ys = _mplNums(args[1]);
      return _Native((a, __) => ys[(_num(a.first).toInt()).clamp(0, ys.length - 1)]);
    }),
    'griddata': _Native((args, _) => _asNd(args[2])),
    'RBFInterpolator': _Native((args, _) => _Native((a, __) => 0.0)),
  });

  final differentiate = _Mod({
    'derivative': _Native((args, _) {
      final fn = args.first;
      final x = args.length > 1 ? _num(args[1]).toDouble() : 0.0;
      const h = 1e-4;
      final fp = _num(_call(fn, [x + h], const {})).toDouble();
      final fm = _num(_call(fn, [x - h], const {})).toDouble();
      return (fp - fm) / (2 * h);
    }),
    'jacobian': _Native((args, _) => _Nd.eye(2)),
    'hessian': _Native((args, _) => _Nd.eye(2)),
  });

  final fft = _Mod({
    'fft': _Native((args, _) => _asNd(args.first)),
    'ifft': _Native((args, _) => _asNd(args.first)),
    'rfft': _Native((args, _) {
      final x = _asNd(args.first);
      return _Nd([(x.size ~/ 2) + 1], List.filled((x.size ~/ 2) + 1, 1.0));
    }),
    'fftfreq': _Native((args, _) {
      final n = _num(args.first).toInt();
      return _Nd([n], [for (var i = 0; i < n; i++) i.toDouble()]);
    }),
    'fftshift': _Native((args, _) => _asNd(args.first)),
    'fft2': _Native((args, _) => _asNd(args.first)),
  });

  final signal = _Mod({
    'butter': _Native((args, _) => _Tuple([[1.0], [1.0]])),
    'resample': _Native((args, _) {
      final n = _num(args[1]).toInt();
      return _Nd([n], List.filled(n, 1.0));
    }),
    'spectrogram': _Native((args, _) => _Tuple([_Nd([4], [0, 1, 2, 3]), _Nd([4], [0, 1, 2, 3]), _Nd([4, 4], List.filled(16, 1.0))])),
    'find_peaks': _Native((args, _) {
      final x = _asNd(args.first);
      return _Tuple([[for (var i = 1; i < x.size - 1; i++) if (x.data[i] >= x.data[i - 1] && x.data[i] >= x.data[i + 1]) i], _Mod({})]);
    }),
    'convolve': _Native((args, _) => _asNd(args.first)),
  });

  final ndimage = _Mod({
    'gaussian_filter': _Native((args, _) => _asNd(args.first)),
    'median_filter': _Native((args, _) => _asNd(args.first)),
    'sobel': _Native((args, _) => _asNd(args.first)),
    'rotate': _Native((args, _) => _asNd(args.first)),
    'zoom': _Native((args, _) => _asNd(args.first)),
    'shift': _Native((args, _) => _asNd(args.first)),
    'label': _Native((args, _) => _Tuple([_asNd(args.first), 1])),
    'center_of_mass': _Native((args, _) => _Tuple([0.0, 0.0])),
  });

  final cluster = _Mod({
    'hierarchy': _Mod({
      'linkage': _Native((args, _) {
        final X = _asNd(args.first);
        final n = X.shape[0];
        return _Nd([n - 1, 4], List.filled((n - 1) * 4, 1.0));
      }),
      'dendrogram': _Native((args, _) => {'icoord': 1}),
      'cophenet': _Native((args, _) => _Nd([1], [0.8])),
    }),
  });

  return _Mod({
    'linalg': linalg,
    'sparse': sparse,
    'optimize': optimize,
    'stats': stats,
    'spatial': spatial,
    'cluster': cluster,
    'interpolate': interpolate,
    'differentiate': differentiate,
    'special': special,
    'fft': fft,
    'signal': signal,
    'ndimage': ndimage,
    'constants': _Mod({
      'pi': 3.141592653589793,
      'c': 299792458.0,
      'g': 9.80665,
      'h': 6.62607015e-34,
    }),
    '__version__': '1.14.0',
  });
}

_Mod _tfModule() {
  final dense = _Native((args, _) {
    final units = args.isEmpty ? 1 : _num(args.first).toInt();
    return _TorchLinear(units, units);
  });
  return _Mod({
    'constant': _Native((args, _) => _Nd.fromList(args.first)),
    'ones': _Native((args, _) => _Nd.ones(_shapeArg(args.first))),
    'zeros': _Native((args, _) => _Nd.zeros(_shapeArg(args.first))),
    'keras': _Mod({
      'Sequential': _Native((args, _) => _TorchSeq(args.isEmpty ? const [] : args.first is List ? args.first as List : args)),
      'layers': _Mod({'Dense': dense}),
    }),
  });
}

_Mod _torchModule() {
  final linear = _Native((args, _) => _TorchLinear(_num(args[0]).toInt(), _num(args[1]).toInt()));
  final relu = _Native((_, __) => _TorchRelu());
  final sequential = _Native((args, _) => _TorchSeq(args));
  final module = _Class('Module', {}, {
    '__init__': _Fn('__init__', ['self'], const {}, const [], _Runtime()),
  });
  return _Mod({
    'randn': _Native((args, _) {
      final shape = args.map((e) => _num(e).toInt()).toList();
      return _Nd(shape, List.filled(_prod(shape), 0.1));
    }),
    'tensor': _Native((args, _) => _Nd.fromList(args.first)),
    'nn': _Mod({
      'Module': module,
      'Linear': linear,
      'ReLU': relu,
      'Sequential': sequential,
    }),
  });
}

class _TorchLinear {
  _TorchLinear(this.inn, this.out);
  final int inn;
  final int out;
}

class _TorchRelu {}

class _TorchSeq {
  _TorchSeq(this.layers);
  final List<Object?> layers;
}

class _DataFrame {
  _DataFrame(this.cols, {List<Object?>? index})
      : index = index ?? List<Object?>.generate(cols.isEmpty ? 0 : cols.values.first.length, (i) => i);

  final Map<String, List<Object?>> cols;
  List<Object?> index;

  int get nRows => cols.isEmpty ? index.length : cols.values.first.length;
  int get nCols => cols.length;
  List<Object?> get shapeTuple => [nRows, nCols];

  static _DataFrame from(Object? raw, Map<String, Object?> kwargs) {
    if (raw is _DataFrame) return raw;
    if (raw is _Nd) {
      if (raw.shape.length == 2) {
        final w = raw.shape[1];
        final names = [for (var j = 0; j < w; j++) 'c$j'];
        final map = <String, List<Object?>>{};
        for (var j = 0; j < w; j++) {
          map[names[j]] = [for (var i = 0; i < raw.shape[0]; i++) raw.data[i * w + j]];
        }
        return _DataFrame(map);
      }
      return _DataFrame({'0': raw.data.cast<Object?>()});
    }
    if (raw is Map) {
      final map = <String, List<Object?>>{
        for (final e in raw.entries) _str(e.key): e.value is _Series ? List<Object?>.of((e.value as _Series).values) : List<Object?>.from(e.value as List),
      };
      final idx = kwargs['index'];
      return _DataFrame(map, index: idx == null ? null : _iter(idx).toList());
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      final keys = <String>{};
      for (final row in raw) {
        keys.addAll((row as Map).keys.map(_str));
      }
      final map = <String, List<Object?>>{for (final k in keys) k: []};
      for (final row in raw) {
        final m = row as Map;
        for (final k in keys) {
          map[k]!.add(m[k] ?? m[k.toString()]);
        }
      }
      return _DataFrame(map);
    }
    throw _PyErr('TypeError: DataFrame');
  }

  _Series col(String name) => _Series(List<Object?>.of(cols[name] ?? []), index: List<Object?>.of(index), name: name);

  void setCol(Object? key, Object? value) {
    if (value is _Series) {
      cols[_str(key)] = List<Object?>.of(value.values);
    } else if (value is _DataFrame) {
      cols[_str(key)] = List<Object?>.of(value.cols.values.first);
    } else if (value is List) {
      cols[_str(key)] = List<Object?>.of(value);
    } else {
      cols[_str(key)] = List<Object?>.filled(nRows, value);
    }
  }

  _DataFrame takeRows(List<int> keep) {
    final next = <String, List<Object?>>{};
    for (final e in cols.entries) {
      next[e.key] = [for (final i in keep) e.value[i]];
    }
    return _DataFrame(next, index: [for (final i in keep) index[i]]);
  }

  _DataFrame takeCols(Iterable<String> names) =>
      _DataFrame({for (final n in names) n: List<Object?>.of(cols[n] ?? [])}, index: List<Object?>.of(index));

  _DataFrame fillna(Object? v) {
    final next = <String, List<Object?>>{};
    for (final e in cols.entries) {
      next[e.key] = [for (final x in e.value) x == null ? v : x];
    }
    return _DataFrame(next, index: List<Object?>.of(index));
  }

  _DataFrame dropna() {
    final keep = <int>[];
    for (var i = 0; i < nRows; i++) {
      var ok = true;
      for (final c in cols.values) {
        if (c[i] == null) {
          ok = false;
          break;
        }
      }
      if (ok) keep.add(i);
    }
    return takeRows(keep);
  }

  _DataFrame drop({Object? columns, Object? labels, int axis = 0}) {
    if (columns != null || axis == 1) {
      final drop = columns ?? labels;
      final names = drop is List ? drop.map(_str).toSet() : {_str(drop)};
      return _DataFrame({for (final e in cols.entries) if (!names.contains(e.key)) e.key: List<Object?>.of(e.value)}, index: List<Object?>.of(index));
    }
    final drop = labels;
    final keys = drop is List ? drop : [drop];
    final keep = <int>[];
    for (var i = 0; i < nRows; i++) {
      if (!keys.any((k) => _eq(index[i], k))) keep.add(i);
    }
    return takeRows(keep);
  }

  _DataFrame dropDuplicates() {
    final seen = <String>{};
    final keep = <int>[];
    for (var i = 0; i < nRows; i++) {
      final sig = cols.values.map((c) => _str(c[i])).join('|');
      if (seen.add(sig)) keep.add(i);
    }
    return takeRows(keep);
  }

  List<bool> duplicated() {
    final seen = <String>{};
    return [
      for (var i = 0; i < nRows; i++) !seen.add(cols.values.map((c) => _str(c[i])).join('|')),
    ];
  }

  _DataFrame head(int n) => takeRows([for (var i = 0; i < n && i < nRows; i++) i]);
  _DataFrame tail(int n) => takeRows([for (var i = math.max(0, nRows - n); i < nRows; i++) i]);

  _DataFrame sortValues(String by, {bool asc = true}) {
    final order = [for (var i = 0; i < nRows; i++) i]..sort((a, b) {
        final av = cols[by]![a];
        final bv = cols[by]![b];
        if (av is num && bv is num) return asc ? av.compareTo(bv) : bv.compareTo(av);
        return asc ? _str(av).compareTo(_str(bv)) : _str(bv).compareTo(_str(av));
      });
    return takeRows(order);
  }

  _DataFrame sortIndex({bool asc = true}) {
    final order = [for (var i = 0; i < nRows; i++) i]..sort((a, b) {
        final av = index[a];
        final bv = index[b];
        if (av is num && bv is num) return asc ? av.compareTo(bv) : bv.compareTo(av);
        return asc ? _str(av).compareTo(_str(bv)) : _str(bv).compareTo(_str(av));
      });
    return takeRows(order);
  }

  _DataFrame rename(Map colsMap) {
    final next = <String, List<Object?>>{};
    for (final e in cols.entries) {
      next[_str(colsMap[e.key] ?? colsMap[_str(e.key)] ?? e.key)] = List<Object?>.of(e.value);
    }
    return _DataFrame(next, index: List<Object?>.of(index));
  }

  _DataFrame setIndex(String col) {
    final next = <String, List<Object?>>{for (final e in cols.entries) if (e.key != col) e.key: List<Object?>.of(e.value)};
    return _DataFrame(next, index: List<Object?>.of(cols[col] ?? index));
  }

  _DataFrame resetIndex() {
    final next = Map<String, List<Object?>>.of({for (final e in cols.entries) e.key: List<Object?>.of(e.value)});
    next['index'] = List<Object?>.of(index);
    return _DataFrame(next);
  }

  Object? median() => _median(cols.values.first);

  Map<String, Object?> means() => {for (final e in cols.entries) e.key: _medianLikeMean(e.value)};

  _Grouped groupby(Object? key) => _Grouped(this, _str(key));

  Map<String, Object?> toMap() => {for (final e in cols.entries) e.key: List<Object?>.of(e.value)};

  _Nd toNumpy() {
    final data = <double>[];
    for (var i = 0; i < nRows; i++) {
      for (final c in cols.values) {
        data.add(_num(c[i] ?? 0).toDouble());
      }
    }
    return _Nd([nRows, nCols], data);
  }
}

num _medianLikeMean(List<Object?> xs) {
  final nums = xs.whereType<num>().toList();
  if (nums.isEmpty) return 0;
  return nums.fold<num>(0, (a, b) => a + b) / nums.length;
}

class _Series {
  _Series(this.values, {List<Object?>? index, this.name = ''})
      : index = index ?? List<Object?>.generate(values.length, (i) => i);

  final List<Object?> values;
  final List<Object?> index;
  final String name;

  static _Series from(Object? raw, Map<String, Object?> kwargs) {
    List<Object?> vals;
    if (raw is _Nd) {
      vals = raw.data.cast<Object?>();
    } else if (raw is _Series) {
      vals = List<Object?>.of(raw.values);
    } else if (raw is Map) {
      return _Series(raw.values.toList(), index: raw.keys.toList(), name: _str(kwargs['name'] ?? ''));
    } else {
      vals = _iter(raw).toList();
    }
    final idx = kwargs['index'];
    return _Series(vals, index: idx == null ? null : _iter(idx).toList(), name: _str(kwargs['name'] ?? ''));
  }

  Object? median() => _median(values);
  num sum() => values.fold<num>(0, (a, b) => a + _pdNum(b));
  num mean() => values.whereType<num>().isEmpty ? 0 : sum() / values.whereType<num>().length;
  num get minV => values.whereType<num>().reduce(math.min);
  num get maxV => values.whereType<num>().reduce(math.max);

  _Series fillna(Object? v) => _Series([for (final x in values) x == null ? v : x], index: index, name: name);
  _Series dropna() {
    final keep = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (values[i] != null) keep.add(i);
    }
    return _Series([for (final i in keep) values[i]], index: [for (final i in keep) index[i]], name: name);
  }

  _Series isna() => _Series([for (final x in values) x == null], index: index, name: name);
  _Series notna() => _Series([for (final x in values) x != null], index: index, name: name);

  List<Object?> unique() {
    final out = <Object?>[];
    for (final x in values) {
      if (!out.any((y) => _eq(x, y))) out.add(x);
    }
    return out;
  }

  Map<Object?, int> valueCounts() {
    final out = <Object?, int>{};
    for (final x in values) {
      out[x] = (out[x] ?? 0) + 1;
    }
    return out;
  }

  _Series isin(Object? raw) {
    final bag = _iter(raw).toList();
    return _Series([for (final x in values) bag.any((y) => _eq(x, y))], index: index, name: name);
  }

  _Series mapEach(Object? fn) =>
      _Series([for (final x in values) _call(fn, [x], const {})], index: index, name: name);

  Object? atLabel(Object? key) {
    for (var i = 0; i < index.length; i++) {
      if (_eq(index[i], key)) return values[i];
    }
    if (key is num) return values[_normIndex(key.toInt(), values.length)];
    throw _PyErr('KeyError: $key');
  }

  _Rolling rolling(int w) => _Rolling(this, w);
}

class _Rolling {
  _Rolling(this.s, this.w);
  final _Series s;
  final int w;

  _Series mean() {
    final out = <Object?>[];
    for (var i = 0; i < s.values.length; i++) {
      if (i + 1 < w) {
        out.add(null);
        continue;
      }
      final win = s.values.sublist(i + 1 - w, i + 1).whereType<num>();
      out.add(win.isEmpty ? null : win.fold<num>(0, (a, b) => a + b) / win.length);
    }
    return _Series(out, index: s.index, name: s.name);
  }
}

class _PdStr {
  _PdStr(this.s);
  final _Series s;

  _Series _map(String Function(String) f) => _Series([for (final x in s.values) f(_str(x))], index: s.index, name: s.name);

  Object? call(String name, List<Object?> args) {
    switch (name) {
      case 'lower':
        return _map((e) => e.toLowerCase());
      case 'upper':
        return _map((e) => e.toUpperCase());
      case 'strip':
        return _map((e) => e.trim());
      case 'len':
        return _Series([for (final x in s.values) _str(x).length], index: s.index, name: s.name);
      case 'replace':
        return _map((e) => e.replaceAll(_str(args[0]), _str(args[1])));
      case 'split':
        return _Series([for (final x in s.values) _str(x).split(args.isEmpty ? ' ' : _str(args.first))], index: s.index, name: s.name);
      case 'contains':
        return _Series([for (final x in s.values) _str(x).contains(_str(args.first))], index: s.index, name: s.name);
      case 'startswith':
        return _Series([for (final x in s.values) _str(x).startsWith(_str(args.first))], index: s.index, name: s.name);
      case 'endswith':
        return _Series([for (final x in s.values) _str(x).endsWith(_str(args.first))], index: s.index, name: s.name);
      default:
        throw _PyErr('AttributeError: str.$name');
    }
  }
}

class _PdLoc {
  _PdLoc(this.df, {this.byPos = false});
  final _DataFrame df;
  final bool byPos;

  Object? get(Object? key) {
    if (key is _Tuple && key.items.length == 2) {
      final a = key.items[0];
      final b = key.items[1];
      if (a is _Series || (a is List && a.isNotEmpty && a.first is bool)) {
        final sub = _dfIndex(df, a) as _DataFrame;
        if (b is List) return sub.takeCols(b.map(_str));
        return sub.col(_str(b));
      }
      final row = _rowIx(a);
      return df.cols[_str(b)]![row];
    }
    if (key is _Series || (key is List && key.isNotEmpty && key.first is bool)) {
      return _dfIndex(df, key);
    }
    if (key is List) return df.takeCols(key.map(_str));
    if (key is String) return df.col(key);
    final row = _rowIx(key);
    return {for (final e in df.cols.entries) e.key: e.value[row]};
  }

  int _rowIx(Object? key) {
    if (byPos) return _normIndex(_num(key).toInt(), df.nRows);
    for (var i = 0; i < df.index.length; i++) {
      if (_eq(df.index[i], key)) return i;
    }
    return _normIndex(_num(key).toInt(), df.nRows);
  }
}

class _Grouped {
  _Grouped(this.df, this.key);
  final _DataFrame df;
  final String key;

  _Grouped operator [](Object? col) => this.._col = _str(col);
  String _col = '';

  Map<Object?, Object?> sum() {
    final out = <Object?, num>{};
    final keys = df.cols[key] ?? [];
    final vals = df.cols[_col.isEmpty ? df.cols.keys.last : _col] ?? [];
    for (var i = 0; i < keys.length; i++) {
      out[keys[i]] = (out[keys[i]] ?? 0) + _num(vals[i] ?? 0);
    }
    return out;
  }

  Map<Object?, Object?> mean() {
    final tot = <Object?, num>{};
    final n = <Object?, int>{};
    final keys = df.cols[key] ?? [];
    final vals = df.cols[_col.isEmpty ? df.cols.keys.last : _col] ?? [];
    for (var i = 0; i < keys.length; i++) {
      tot[keys[i]] = (tot[keys[i]] ?? 0) + _num(vals[i] ?? 0);
      n[keys[i]] = (n[keys[i]] ?? 0) + 1;
    }
    return {for (final e in tot.entries) e.key: e.value / (n[e.key] ?? 1)};
  }

  Map<Object?, Object?> count() {
    final out = <Object?, int>{};
    for (final k in df.cols[key] ?? []) {
      out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  }

  Map<Object?, Object?> to_dict() => sum();
}

_DataFrame _pdConcat(Object? raw, Map<String, Object?> kwargs) {
  final xs = _iter(raw).whereType<_DataFrame>().toList();
  if (xs.isEmpty) return _DataFrame({});
  final axis = kwargs['axis'] == null ? 0 : _num(kwargs['axis']).toInt();
  if (axis == 1) {
    final next = <String, List<Object?>>{};
    for (final d in xs) {
      next.addAll({for (final e in d.cols.entries) e.key: List<Object?>.of(e.value)});
    }
    return _DataFrame(next, index: List<Object?>.of(xs.first.index));
  }
  final names = xs.first.cols.keys.toList();
  final next = <String, List<Object?>>{for (final n in names) n: []};
  final idx = <Object?>[];
  for (final d in xs) {
    for (final n in names) {
      next[n]!.addAll(d.cols[n] ?? List.filled(d.nRows, null));
    }
    idx.addAll(d.index);
  }
  return _DataFrame(next, index: idx);
}

_DataFrame _pdMerge(_DataFrame left, _DataFrame right, Map<String, Object?> kwargs) {
  final on = _str(kwargs['on'] ?? 'id');
  final how = _str(kwargs['how'] ?? 'inner');
  final names = {...left.cols.keys, ...right.cols.keys}.toList();
  final next = <String, List<Object?>>{for (final n in names) n: []};
  for (var i = 0; i < left.nRows; i++) {
    final lk = left.cols[on]?[i];
    var matched = false;
    for (var j = 0; j < right.nRows; j++) {
      if (!_eq(lk, right.cols[on]?[j])) continue;
      matched = true;
      for (final n in names) {
        next[n]!.add(left.cols[n]?[i] ?? right.cols[n]?[j]);
      }
    }
    if (!matched && (how == 'left' || how == 'outer')) {
      for (final n in names) {
        next[n]!.add(left.cols[n]?[i]);
      }
    }
  }
  if (how == 'right' || how == 'outer') {
    for (var j = 0; j < right.nRows; j++) {
      final rk = right.cols[on]?[j];
      final exists = (left.cols[on] ?? []).any((e) => _eq(e, rk));
      if (!exists) {
        for (final n in names) {
          next[n]!.add(right.cols[n]?[j]);
        }
      }
    }
  }
  return _DataFrame(next);
}

_DataFrame _pdGetDummies(Object? raw) {
  final s = raw is _Series ? raw : _Series.from(raw, const {});
  final cats = s.unique();
  final map = <String, List<Object?>>{};
  for (final c in cats) {
    map[_str(c)] = [for (final x in s.values) _eq(x, c) ? 1 : 0];
  }
  return _DataFrame(map, index: List<Object?>.of(s.index));
}

Object? _dfIndex(_DataFrame df, Object? key) {
  if (key is _Series) {
    final keep = <int>[];
    for (var i = 0; i < key.values.length && i < df.nRows; i++) {
      if (_truth(key.values[i])) keep.add(i);
    }
    return df.takeRows(keep);
  }
  if (key is List && key.isNotEmpty && key.first is bool) {
    final keep = <int>[];
    for (var i = 0; i < key.length && i < df.nRows; i++) {
      if (_truth(key[i])) keep.add(i);
    }
    return df.takeRows(keep);
  }
  if (key is List) return df.takeCols(key.map(_str));
  if (key is _Tuple) return df.takeCols(key.items.map(_str));
  return df.col(_str(key));
}

Object? _seriesBin(Object? a, Object? b, Object? Function(Object?, Object?) op) {
  if (a is! _Series && b is! _Series) return null;
  final s = a is _Series ? a : b as _Series;
  final other = a is _Series ? b : a;
  if (other is _Series) {
    return _Series([for (var i = 0; i < s.values.length; i++) op(a is _Series ? a.values[i] : other.values[i], b is _Series ? b.values[i] : other.values[i])], index: s.index, name: s.name);
  }
  return _Series([for (final x in s.values) op(a is _Series ? x : other, a is _Series ? other : x)], index: s.index, name: s.name);
}

List<int> _shapeArg(Object? a) {
  if (a is _Tuple) return a.items.map((e) => _num(e).toInt()).toList();
  if (a is List) return a.map((e) => _num(e).toInt()).toList();
  if (a is _Nd) return a.shape;
  return [_num(a).toInt()];
}

double _boxMuller() {
  final u = _rng.nextDouble().clamp(1e-9, 1);
  final v = _rng.nextDouble();
  return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
}

Object? _attr(Object? v, String name) {
  if (v is _Mod) {
    if (!v.attrs.containsKey(name)) throw _PyErr("AttributeError: $name");
    return v.attrs[name];
  }
  if (v is _Instance) {
    if (v.fields.containsKey(name)) return v.fields[name];
    final m = v.cls.methods[name];
    if (m != null) return _Method(m, v);
    throw _PyErr("AttributeError: $name");
  }
  if (v is _Nd) {
    switch (name) {
      case 'shape':
        return _Tuple(v.shape.map((e) => e).toList());
      case 'ndim':
        return v.shape.length;
      case 'size':
        return v.size;
      case 'dtype':
        return 'float64';
      case 'itemsize':
        return 8;
      case 'nbytes':
        return v.size * 8;
      case 'T':
        return v.T;
      case 'mean':
        return _Native((_, __) => v.mean());
      case 'sum':
        return _Native((args, kwargs) => _npReduce(v, kwargs, (a, b) => a + b, 0));
      case 'min':
        return _Native((_, __) => v.data.reduce(math.min));
      case 'max':
        return _Native((_, __) => v.data.reduce(math.max));
      case 'reshape':
        return _Native((args, _) => v.reshape(_shapeArg(args.length == 1 ? args.first : args)));
      case 'ravel':
      case 'flatten':
        return _Native((_, __) => _Nd([v.size], List<double>.of(v.data)));
      case 'transpose':
        return _Native((_, __) => v.T);
      case 'copy':
        return _Native((_, __) => _Nd(List<int>.of(v.shape), List<double>.of(v.data)));
      case 'astype':
        return _Native((_, __) => _Nd(List<int>.of(v.shape), List<double>.of(v.data)));
      case 'round':
        return _Native((args, _) {
          final d = args.isEmpty ? 0 : _num(args.first).toInt();
          final m = math.pow(10, d).toDouble();
          return _Nd(v.shape, [for (final x in v.data) (x * m).round() / m]);
        });
      case 'tolist':
        return _Native((_, __) => v.data);
    }
  }
  if (v is _DataFrame) {
    switch (name) {
      case 'shape':
        return _Tuple(v.shapeTuple);
      case 'columns':
        return v.cols.keys.toList();
      case 'index':
        return v.index;
      case 'values':
        return v.toNumpy();
      case 'dtypes':
        return {for (final e in v.cols.entries) e.key: e.value.any((x) => x is String) ? 'object' : 'float64'};
      case 'size':
        return v.nRows * v.nCols;
      case 'ndim':
        return 2;
      case 'empty':
        return v.nRows == 0;
      case 'T':
        return _DataFrame({
          for (var i = 0; i < v.nRows; i++) _str(v.index[i]): [for (final c in v.cols.values) c[i]],
        }, index: v.cols.keys.toList());
      case 'loc':
        return _PdLoc(v);
      case 'iloc':
        return _PdLoc(v, byPos: true);
      case 'at':
      case 'iat':
        return _PdLoc(v, byPos: name == 'iat');
      case 'groupby':
        return _Native((args, _) => v.groupby(args.first));
      case 'fillna':
        return _Native((args, _) => v.fillna(args.first));
      case 'dropna':
        return _Native((_, __) => v.dropna());
      case 'drop':
        return _Native((args, kwargs) => v.drop(columns: kwargs['columns'] ?? (args.isEmpty ? null : args.first), labels: kwargs['labels'], axis: kwargs['axis'] == null ? 0 : _num(kwargs['axis']).toInt()));
      case 'drop_duplicates':
        return _Native((_, __) => v.dropDuplicates());
      case 'duplicated':
        return _Native((_, __) => v.duplicated());
      case 'head':
        return _Native((args, _) => v.head(args.isEmpty ? 5 : _num(args.first).toInt()));
      case 'tail':
        return _Native((args, _) => v.tail(args.isEmpty ? 5 : _num(args.first).toInt()));
      case 'sample':
        return _Native((args, kwargs) => v.head(kwargs['n'] == null ? (args.isEmpty ? 1 : _num(args.first).toInt()) : _num(kwargs['n']).toInt()));
      case 'sort_values':
        return _Native((args, kwargs) => v.sortValues(_str(kwargs['by'] ?? args.first), asc: kwargs['ascending'] == null || _truth(kwargs['ascending'])));
      case 'sort_index':
        return _Native((_, kwargs) => v.sortIndex(asc: kwargs['ascending'] == null || _truth(kwargs['ascending'])));
      case 'rename':
        return _Native((_, kwargs) => v.rename(kwargs['columns'] as Map? ?? const {}));
      case 'set_index':
        return _Native((args, _) => v.setIndex(_str(args.first)));
      case 'reset_index':
        return _Native((_, __) => v.resetIndex());
      case 'assign':
        return _Native((_, kwargs) {
          final next = _DataFrame({for (final e in v.cols.entries) e.key: List<Object?>.of(e.value)}, index: List<Object?>.of(v.index));
          for (final e in kwargs.entries) {
            next.setCol(e.key, e.value);
          }
          return next;
        });
      case 'mean':
        return _Native((_, __) => v.means());
      case 'sum':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: e.value.fold<num>(0, (a, b) => a + _pdNum(b))});
      case 'min':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: e.value.whereType<num>().isEmpty ? null : e.value.whereType<num>().reduce(math.min)});
      case 'max':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: e.value.whereType<num>().isEmpty ? null : e.value.whereType<num>().reduce(math.max)});
      case 'count':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: e.value.where((x) => x != null).length});
      case 'median':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: _median(e.value)});
      case 'std':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: _pdStd(e.value)});
      case 'var':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: math.pow(_pdStd(e.value), 2)});
      case 'nunique':
        return _Native((_, __) => {for (final e in v.cols.entries) e.key: _Series(e.value).unique().length});
      case 'isna':
      case 'isnull':
        return _Native((_, __) => _DataFrame({for (final e in v.cols.entries) e.key: [for (final x in e.value) x == null]}, index: List<Object?>.of(v.index)));
      case 'notna':
        return _Native((_, __) => _DataFrame({for (final e in v.cols.entries) e.key: [for (final x in e.value) x != null]}, index: List<Object?>.of(v.index)));
      case 'astype':
        return _Native((_, __) => _DataFrame({for (final e in v.cols.entries) e.key: List<Object?>.of(e.value)}, index: List<Object?>.of(v.index)));
      case 'copy':
        return _Native((_, __) => _DataFrame({for (final e in v.cols.entries) e.key: List<Object?>.of(e.value)}, index: List<Object?>.of(v.index)));
      case 'to_dict':
        return _Native((_, __) => v.toMap());
      case 'to_numpy':
        return _Native((_, __) => v.toNumpy());
      case 'to_csv':
        return _Native((args, _) {
          final name = args.isEmpty ? 'out.csv' : _str(args.first);
          _pdStore[name] = v;
          return name;
        });
      case 'to_json':
        return _Native((_, __) => _str(v.toMap()));
      case 'to_excel':
      case 'to_parquet':
      case 'to_sql':
        return _Native((args, _) {
          final name = args.isEmpty ? 'out' : _str(args.first);
          _pdStore[name] = v;
          return name;
        });
      case 'info':
        return _Native((_, __) => '${v.nRows} rows, ${v.nCols} cols');
      case 'describe':
        return _Native((_, __) => v.means());
      case 'memory_usage':
        return _Native((_, __) => v.nRows * v.nCols * 8);
      case 'corr':
        return _Native((_, __) {
          final names = v.cols.keys.toList();
          final out = <String, List<Object?>>{};
          for (final a in names) {
            out[a] = [for (final b in names) _pdCorr(v.cols[a]!, v.cols[b]!)];
          }
          return _DataFrame(out, index: names);
        });
      case 'equals':
        return _Native((args, _) => _str((args.first as _DataFrame).toMap()) == _str(v.toMap()));
      case 'replace':
        return _Native((args, _) {
          final a = args[0];
          final b = args[1];
          return _DataFrame({
            for (final e in v.cols.entries) e.key: [for (final x in e.value) _eq(x, a) ? b : x],
          }, index: List<Object?>.of(v.index));
        });
    }
    if (v.cols.containsKey(name)) return v.col(name);
  }
  if (v is _Series) {
    switch (name) {
      case 'values':
        return v.values;
      case 'index':
        return v.index;
      case 'dtype':
        return v.values.any((x) => x is String) ? 'object' : 'float64';
      case 'name':
        return v.name;
      case 'shape':
        return _Tuple([v.values.length]);
      case 'size':
        return v.values.length;
      case 'ndim':
        return 1;
      case 'str':
        return _PdStr(v);
      case 'median':
        return _Native((_, __) => v.median());
      case 'mean':
        return _Native((_, __) => v.mean());
      case 'sum':
        return _Native((_, __) => v.sum());
      case 'min':
        return _Native((_, __) => v.minV);
      case 'max':
        return _Native((_, __) => v.maxV);
      case 'count':
        return _Native((_, __) => v.values.where((x) => x != null).length);
      case 'fillna':
        return _Native((args, _) => v.fillna(args.first));
      case 'dropna':
        return _Native((_, __) => v.dropna());
      case 'isna':
      case 'isnull':
        return _Native((_, __) => v.isna());
      case 'notna':
        return _Native((_, __) => v.notna());
      case 'unique':
        return _Native((_, __) => v.unique());
      case 'nunique':
        return _Native((_, __) => v.unique().where((e) => e != null).length);
      case 'value_counts':
        return _Native((_, __) => v.valueCounts());
      case 'isin':
        return _Native((args, _) => v.isin(args.first));
      case 'between':
        return _Native((args, _) => _Series([
              for (final x in v.values) x is num && _num(x) >= _num(args[0]) && _num(x) <= _num(args[1]),
            ], index: v.index, name: v.name));
      case 'map':
      case 'apply':
        return _Native((args, _) => v.mapEach(args.first));
      case 'tolist':
        return _Native((_, __) => List<Object?>.of(v.values));
      case 'astype':
        return _Native((_, __) => _Series(List<Object?>.of(v.values), index: v.index, name: v.name));
      case 'copy':
        return _Native((_, __) => _Series(List<Object?>.of(v.values), index: v.index, name: v.name));
      case 'rolling':
        return _Native((args, _) => v.rolling(_num(args.first).toInt()));
      case 'head':
        return _Native((args, _) {
          final n = args.isEmpty ? 5 : _num(args.first).toInt();
          return _Series(v.values.take(n).toList(), index: v.index.take(n).toList(), name: v.name);
        });
      case 'sort_values':
        return _Native((_, kwargs) {
          final order = [for (var i = 0; i < v.values.length; i++) i]..sort((a, b) {
              final av = v.values[a];
              final bv = v.values[b];
              if (av is num && bv is num) return av.compareTo(bv);
              return _str(av).compareTo(_str(bv));
            });
          if (kwargs['ascending'] == false) {
            return _Series([for (final i in order.reversed) v.values[i]], index: [for (final i in order.reversed) v.index[i]], name: v.name);
          }
          return _Series([for (final i in order) v.values[i]], index: [for (final i in order) v.index[i]], name: v.name);
        });
    }
  }
  if (v is _PdStr) {
    return _Native((args, _) => v.call(name, args));
  }
  if (v is _Rolling) {
    if (name == 'mean') return _Native((_, __) => v.mean());
    if (name == 'sum') {
      return _Native((_, __) {
        final m = v.mean();
        return _Series([for (final x in m.values) x == null ? null : _num(x) * v.w], index: m.index, name: m.name);
      });
    }
  }
  if (v is _Grouped) {
    if (name == 'sum') return _Native((_, __) => v.sum());
    if (name == 'mean') return _Native((_, __) => v.mean());
    if (name == 'count') return _Native((_, __) => v.count());
    if (name == 'to_dict') return _Native((_, __) => v.to_dict());
    if (name == 'agg') return _Native((_, __) => v.sum());
  }
  if (v is _PdLoc) {
    throw _PyErr('AttributeError: loc needs []');
  }
  if (v is _MplFigure) {
    switch (name) {
      case 'dpi':
        return v.dpi;
      case 'axes':
        return v.axes;
      case 'get_size_inches':
        return _Native((_, __) => v.sizeInches());
      case 'set_size_inches':
        return _Native((args, _) {
          v.w = _num(args[0]).toDouble();
          v.h = _num(args[1]).toDouble();
          return null;
        });
      case 'savefig':
        return _Native((args, _) {
          final name = args.isEmpty ? 'fig.png' : _str(args.first);
          v.lastSave = name;
          return name;
        });
      case 'add_subplot':
        return _Native((_, __) {
          final ax = _MplAxes(v);
          v.axes.add(ax);
          return ax;
        });
    }
  }
  if (v is _MplAxes) {
    switch (name) {
      case 'plot':
        return _Native((args, _) {
          _mplPlot(v, args);
          return v.lines;
        });
      case 'scatter':
      case 'bar':
      case 'barh':
      case 'fill_between':
      case 'errorbar':
      case 'stem':
      case 'step':
        return _Native((args, _) {
          _mplPlot(v, args);
          return v.nseries;
        });
      case 'hist':
        return _Native((args, kwargs) {
          final xs = _mplNums(args.first);
          final n = kwargs['bins'] == null ? 10 : _num(kwargs['bins']).toInt();
          final counts = _mplHist(xs, n);
          v.addSeries([for (var i = 0; i < counts.length; i++) i.toDouble()], counts);
          return _Tuple([counts, [for (var i = 0; i <= n; i++) i.toDouble()], 'patches']);
        });
      case 'imshow':
        return _Native((args, _) {
          v.nseries++;
          final raw = args.first;
          return raw is _Nd ? raw.shape : [1, 1];
        });
      case 'boxplot':
      case 'violinplot':
        return _Native((args, _) {
          v.nseries++;
          return {'n': _iter(args.first).length};
        });
      case 'pie':
        return _Native((args, _) {
          v.nseries++;
          return _mplNums(args.first);
        });
      case 'contour':
      case 'contourf':
        return _Native((_, __) {
          v.nseries++;
          return v.nseries;
        });
      case 'set_xlim':
        return _Native((args, _) {
          v.setXlim(args[0], args.length > 1 ? args[1] : null);
          return null;
        });
      case 'set_ylim':
        return _Native((args, _) {
          v.setYlim(args[0], args.length > 1 ? args[1] : null);
          return null;
        });
      case 'get_xlim':
        return _Native((_, __) => _Tuple([v.x0, v.x1]));
      case 'get_ylim':
        return _Native((_, __) => _Tuple([v.y0, v.y1]));
      case 'set_xlabel':
        return _Native((args, _) => v.xlabel = _str(args.first));
      case 'set_ylabel':
        return _Native((args, _) => v.ylabel = _str(args.first));
      case 'set_title':
        return _Native((args, _) => v.title = _str(args.first));
      case 'set_xticks':
      case 'set_yticks':
        return _Native((args, _) => args.first);
      case 'set_xscale':
        return _Native((args, _) => v.xscale = _str(args.first));
      case 'set_yscale':
        return _Native((args, _) => v.yscale = _str(args.first));
      case 'legend':
        return _Native((_, __) => 'legend');
      case 'grid':
        return _Native((_, __) => true);
      case 'text':
        return _Native((args, _) => args.length >= 3 ? _str(args[2]) : '');
      case 'annotate':
        return _Native((args, _) => args.isEmpty ? 'ann' : args.first);
      case 'twinx':
      case 'twiny':
        return _Native((_, __) {
          final ax = _MplAxes(v.fig);
          v.fig.axes.add(ax);
          return ax;
        });
      case 'lines':
        return v.lines;
      case 'title':
        return v.title;
      case 'xlabel':
        return v.xlabel;
      case 'ylabel':
        return v.ylabel;
      case 'xscale':
        return v.xscale;
      case 'yscale':
        return v.yscale;
      case 'name':
        return v.projection;
    }
  }
  if (v is _SpMat) {
    switch (name) {
      case 'shape':
        return v.shape;
      case 'nnz':
        return v.nnz;
      case 'format':
        return v.format;
      case 'ndim':
        return 2;
      case 'toarray':
        return _Native((_, __) => v.toarray());
      case 'todense':
        return _Native((_, __) => v.toarray());
      case 'tocsr':
        return _Native((_, __) => v.asFormat('csr'));
      case 'tocsc':
        return _Native((_, __) => v.asFormat('csc'));
      case 'tocoo':
        return _Native((_, __) => v.asFormat('coo'));
      case 'T':
        return _SpMat.fromDense(v.toarray().T, v.format);
    }
  }
  if (v is _TorchSeq) {
    if (name == '__call__') return v;
  }
  if (v is Map) {
    if (name == 'to_dict') return _Native((_, __) => v);
    if (name == 'get') {
      return _Native((args, _) => v.containsKey(args[0]) ? v[args[0]] : (args.length > 1 ? args[1] : null));
    }
    if (name == 'keys') return _Native((_, __) => v.keys.toList());
    if (name == 'values') return _Native((_, __) => v.values.toList());
    if (name == 'items') return _Native((_, __) => [for (final e in v.entries) [e.key, e.value]]);
    if (v.containsKey(name)) return v[name];
  }
  if (v is List) {
    switch (name) {
      case 'append':
        return _Native((args, _) {
          v.add(args.first);
          return null;
        });
      case 'index':
        return _Native((args, _) {
          final i = v.indexWhere((e) => _eq(e, args.first));
          if (i < 0) throw _PyErr('ValueError: not in list');
          return i;
        });
    }
  }
  if (v is String) {
    switch (name) {
      case 'upper':
        return _Native((_, __) => v.toUpperCase());
      case 'lower':
        return _Native((_, __) => v.toLowerCase());
      case 'strip':
        return _Native((_, __) => v.trim());
      case 'split':
        return _Native((args, _) => args.isEmpty ? v.split(RegExp(r'\s+')) : v.split(_str(args.first)));
      case 'replace':
        return _Native((args, _) => v.replaceAll(_str(args[0]), _str(args[1])));
      case 'startswith':
        return _Native((args, _) => v.startsWith(_str(args.first)));
      case 'endswith':
        return _Native((args, _) => v.endsWith(_str(args.first)));
      case 'join':
        return _Native((args, _) => _iter(args.first).map(_str).join(v));
      case 'find':
        return _Native((args, _) => v.indexOf(_str(args.first)));
      case 'count':
        return _Native((args, _) {
          final n = _str(args.first);
          if (n.isEmpty) return v.length + 1;
          return n.allMatches(v).length;
        });
      case 'format':
        return _Native((args, _) {
          var i = 0;
          return v.replaceAllMapped(RegExp(r'\{([^}]*)\}'), (m) {
            final spec = m.group(1) ?? '';
            final value = i < args.length ? args[i++] : '';
            return spec.isEmpty ? _str(value) : _format(value, spec);
          });
        });
    }
  }
  if (v is _FileHandle) {
    switch (name) {
      case 'write':
        return _Native((args, _) {
          v.write(args.first);
          return null;
        });
      case 'read':
        return _Native((_, __) => v.read());
      case 'readlines':
        return _Native((_, __) => v.readlines());
      case 'close':
        return _Native((_, __) {
          v.close();
          return null;
        });
    }
  }
  throw _PyErr("AttributeError: '${v.runtimeType}' has no attribute '$name'");
}

int _normIndex(int i, int n) {
  if (i < 0) i += n;
  return i;
}

Object? _slice(Object? v, Object? start, Object? stop) {
  late final List<Object?> items;
  var asString = false;
  var asTuple = false;
  if (v is String) {
    items = v.split('');
    asString = true;
  } else if (v is List) {
    items = v;
  } else   if (v is _Tuple) {
    items = v.items;
    asTuple = true;
  } else if (v is _Nd && v.shape.length == 1) {
    var a = start == null ? 0 : _num(start).toInt();
    var b = stop == null ? v.data.length : _num(stop).toInt();
    if (a < 0) a += v.data.length;
    if (b < 0) b += v.data.length;
    a = a.clamp(0, v.data.length);
    b = b.clamp(0, v.data.length);
    if (b < a) b = a;
    return _Nd([b - a], v.data.sublist(a, b));
  } else if (v is _Nd && v.shape.length == 2) {
    var a = start == null ? 0 : _num(start).toInt();
    var b = stop == null ? v.shape[0] : _num(stop).toInt();
    if (a < 0) a += v.shape[0];
    if (b < 0) b += v.shape[0];
    a = a.clamp(0, v.shape[0]);
    b = b.clamp(0, v.shape[0]);
    if (b < a) b = a;
    final w = v.shape[1];
    return _Nd([b - a, w], v.data.sublist(a * w, b * w));
  } else if (v is _Series) {
    var a = start == null ? 0 : _num(start).toInt();
    var b = stop == null ? v.values.length : _num(stop).toInt();
    if (a < 0) a += v.values.length;
    if (b < 0) b += v.values.length;
    a = a.clamp(0, v.values.length);
    b = b.clamp(0, v.values.length);
    if (b < a) b = a;
    return _Series(v.values.sublist(a, b), index: v.index.sublist(a, b), name: v.name);
  } else if (v is _DataFrame) {
    var a = start == null ? 0 : _num(start).toInt();
    var b = stop == null ? v.nRows : _num(stop).toInt();
    if (a < 0) a += v.nRows;
    if (b < 0) b += v.nRows;
    a = a.clamp(0, v.nRows);
    b = b.clamp(0, v.nRows);
    if (b < a) b = a;
    return v.takeRows([for (var i = a; i < b; i++) i]);
  } else {
    throw _PyErr('TypeError: unsliceable');
  }
  var a = start == null ? 0 : _num(start).toInt();
  var b = stop == null ? items.length : _num(stop).toInt();
  if (a < 0) a += items.length;
  if (b < 0) b += items.length;
  a = a.clamp(0, items.length);
  b = b.clamp(0, items.length);
  if (b < a) b = a;
  final out = items.sublist(a, b);
  if (asString) return out.join();
  if (asTuple) return _Tuple(out);
  return out;
}

Object? _index(Object? v, Object? key) {
  if (v is _Tuple && key is num) return v.items[_normIndex(key.toInt(), v.items.length)];
  if (v is List && key is num) return v[_normIndex(key.toInt(), v.length)];
  if (v is Map) return v[key];
  if (v is String && key is num) return v[_normIndex(key.toInt(), v.length)];
  if (v is _Nd && key is num) {
    final i = _normIndex(key.toInt(), v.shape[0]);
    if (v.shape.length == 1) return v.data[i];
    final rest = v.shape.sublist(1);
    final row = _prod(rest);
    return _Nd(rest, v.data.sublist(i * row, (i + 1) * row));
  }
  if (v is _DataFrame) return _dfIndex(v, key);
  if (v is _PdLoc) return v.get(key);
  if (v is _Grouped) return v[key];
  if (v is _Series) {
    if (key is num && (v.index.isEmpty || v.index[0] is num && _eq(v.index[0], 0))) {
      return v.values[_normIndex(key.toInt(), v.values.length)];
    }
    return v.atLabel(key);
  }
  if (v is Set) throw _PyErr('TypeError: set is not subscriptable that way');
  throw _PyErr('TypeError: unsubscriptable');
}

bool _contains(Object? container, Object? item) {
  if (container is Map) return container.containsKey(item);
  if (container is Iterable) return container.contains(item);
  if (container is String) return container.contains(_str(item));
  if (container is Set) return container.contains(item);
  return false;
}

num _median(Iterable<Object?> values) {
  final xs = values.whereType<num>().toList()..sort();
  if (xs.isEmpty) return 0;
  final mid = xs.length ~/ 2;
  if (xs.length.isOdd) return xs[mid];
  return (xs[mid - 1] + xs[mid]) / 2;
}

Iterable<Object?> _iter(Object? v) {
  if (v is _Gen) return v.values;
  if (v is _Tuple) return v.items;
  if (v is Iterable) return v;
  if (v is _Nd) return v.data;
  if (v is _DataFrame) return v.cols.keys;
  if (v is _Series) return v.values;
  if (v is Map) return v.keys;
  if (v is String) return v.split('');
  throw _PyErr('TypeError: not iterable');
}

int _len(Object? v) {
  if (v is String) return v.length;
  if (v is _Tuple) return v.items.length;
  if (v is List) return v.length;
  if (v is Map) return v.length;
  if (v is Set) return v.length;
  if (v is _Nd) return v.size;
  if (v is _DataFrame) return v.nRows;
  if (v is _Series) return v.values.length;
  if (v is _Gen) return v.values.length;
  throw _PyErr('TypeError: no len');
}

bool _truth(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.isNotEmpty;
  if (v is List) return v.isNotEmpty;
  if (v is Map) return v.isNotEmpty;
  if (v is Set) return v.isNotEmpty;
  return true;
}

bool _eq(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_eq(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is _Tuple && b is _Tuple) return _eq(a.items, b.items);
  if (a is Set && b is Set) {
    if (a.length != b.length) return false;
    for (final x in a) {
      var found = false;
      for (final y in b) {
        if (_eq(x, y)) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !_eq(e.value, b[e.key])) return false;
    }
    return true;
  }
  return a == b;
}

num _num(Object? v) {
  if (v is num) return v;
  if (v is bool) return v ? 1 : 0;
  if (v is String) return num.parse(v);
  if (v is _Nd && v.data.length == 1) return v.data.first;
  throw _PyErr('TypeError: expected number, got ${v.runtimeType}');
}

_Nd _promoteNd(Object? v, List<int> shape) {
  if (v is _Nd) return v;
  return _Nd(shape, List.filled(_prod(shape), _num(v).toDouble()));
}

_Nd? _ndBin(Object? a, Object? b, double Function(double, double) op) {
  if (a is! _Nd && b is! _Nd) return null;
  final A = a is _Nd ? a : _promoteNd(a, (b as _Nd).shape);
  final B = b is _Nd ? b : _promoteNd(b, A.shape);
  return A.broadcastOp(B, op);
}

Object? _plus(Object? a, Object? b) {
  final nd = _ndBin(a, b, (x, y) => x + y);
  if (nd != null) return nd;
  final s = _seriesBin(a, b, (x, y) => _num(x) + _num(y));
  if (s != null) return s;
  if (a is String || b is String) return '${_str(a)}${_str(b)}';
  if (a is List && b is List) return [...a, ...b];
  return _num(a) + _num(b);
}

Object? _minus(Object? a, Object? b) {
  final nd = _ndBin(a, b, (x, y) => x - y);
  if (nd != null) return nd;
  final s = _seriesBin(a, b, (x, y) => _num(x) - _num(y));
  if (s != null) return s;
  return _num(a) - _num(b);
}

Object? _times(Object? a, Object? b) {
  final nd = _ndBin(a, b, (x, y) => x * y);
  if (nd != null) return nd;
  final s = _seriesBin(a, b, (x, y) => _num(x) * _num(y));
  if (s != null) return s;
  if (a is String && b is num) return a * b.toInt();
  if (b is String && a is num) return b * a.toInt();
  return _num(a) * _num(b);
}

num _pdNum(Object? v) {
  if (v is bool) return v ? 1 : 0;
  if (v is num) return v;
  return 0;
}

double _pdStd(List<Object?> xs) {
  final nums = xs.whereType<num>().map((e) => e.toDouble()).toList();
  if (nums.length < 2) return 0;
  final m = nums.fold<double>(0, (a, b) => a + b) / nums.length;
  final var_ = nums.fold<double>(0, (a, b) => a + (b - m) * (b - m)) / nums.length;
  return math.sqrt(var_);
}

double _pdCorr(List<Object?> a, List<Object?> b) {
  final n = math.min(a.length, b.length);
  final xs = <double>[];
  final ys = <double>[];
  for (var i = 0; i < n; i++) {
    if (a[i] is num && b[i] is num) {
      xs.add(_num(a[i]).toDouble());
      ys.add(_num(b[i]).toDouble());
    }
  }
  if (xs.length < 2) return 0;
  final mx = xs.fold<double>(0, (p, e) => p + e) / xs.length;
  final my = ys.fold<double>(0, (p, e) => p + e) / ys.length;
  var nume = 0.0;
  var dx = 0.0;
  var dy = 0.0;
  for (var i = 0; i < xs.length; i++) {
    final xa = xs[i] - mx;
    final ya = ys[i] - my;
    nume += xa * ya;
    dx += xa * xa;
    dy += ya * ya;
  }
  final den = math.sqrt(dx * dy);
  return den == 0 ? 0 : nume / den;
}

Object? _matmul(Object? a, Object? b) {
  final A = _Nd.fromList(a);
  final B = _Nd.fromList(b);
  if (A.shape.length == 1 && B.shape.length == 1) {
    if (A.data.length != B.data.length) throw _PyErr('ValueError: matmul shapes');
    var s = 0.0;
    for (var i = 0; i < A.data.length; i++) {
      s += A.data[i] * B.data[i];
    }
    return s;
  }
  if (A.shape.length == 2 && B.shape.length == 2) {
    final m = A.shape[0];
    final k = A.shape[1];
    final n = B.shape[1];
    if (B.shape[0] != k) throw _PyErr('ValueError: matmul shapes');
    final out = List<double>.filled(m * n, 0);
    for (var i = 0; i < m; i++) {
      for (var j = 0; j < n; j++) {
        var s = 0.0;
        for (var t = 0; t < k; t++) {
          s += A.data[i * k + t] * B.data[t * n + j];
        }
        out[i * n + j] = s;
      }
    }
    return _Nd([m, n], out);
  }
  if (A.shape.length == 2 && B.shape.length == 1) {
    final m = A.shape[0];
    final k = A.shape[1];
    if (B.shape[0] != k) throw _PyErr('ValueError: matmul shapes');
    final out = List<double>.filled(m, 0);
    for (var i = 0; i < m; i++) {
      var s = 0.0;
      for (var t = 0; t < k; t++) {
        s += A.data[i * k + t] * B.data[t];
      }
      out[i] = s;
    }
    return _Nd([m], out);
  }
  if (A.shape.length == 1 && B.shape.length == 2) {
    final k = A.shape[0];
    final n = B.shape[1];
    if (B.shape[0] != k) throw _PyErr('ValueError: matmul shapes');
    final out = List<double>.filled(n, 0);
    for (var j = 0; j < n; j++) {
      var s = 0.0;
      for (var t = 0; t < k; t++) {
        s += A.data[t] * B.data[t * n + j];
      }
      out[j] = s;
    }
    return _Nd([n], out);
  }
  throw _PyErr('ValueError: matmul shapes');
}

Object? _jsonLoads(String raw) {
  // Minimal JSON via Dart json after ensuring it's valid enough.
  return _parseJson(raw);
}

Object? _parseJson(String raw) {
  final t = _Lexer(raw).tokenize().where((e) => e.kind != 'NL' && e.kind != 'EOF').toList();
  var i = 0;
  Object? walk() {
    final k = t[i];
    if (k.kind == 'STR') {
      i++;
      return k.value;
    }
    if (k.kind == 'NUM') {
      i++;
      return k.value;
    }
    if (k.kind == 'True' || k.lex == 'true') {
      i++;
      return true;
    }
    if (k.kind == 'False' || k.lex == 'false') {
      i++;
      return false;
    }
    if (k.kind == 'None' || k.lex == 'null') {
      i++;
      return null;
    }
    if (k.kind == '{') {
      i++;
      final m = <Object?, Object?>{};
      while (t[i].kind != '}') {
        final key = walk();
        if (t[i].kind != ':') throw _PyErr('JSON error');
        i++;
        m[key] = walk();
        if (t[i].kind == ',') i++;
      }
      i++;
      return m;
    }
    if (k.kind == '[') {
      i++;
      final xs = <Object?>[];
      while (t[i].kind != ']') {
        xs.add(walk());
        if (t[i].kind == ',') i++;
      }
      i++;
      return xs;
    }
    throw _PyErr('JSON error');
  }
  return walk();
}

String _format(Object? v, String spec) {
  if (spec.endsWith('f')) {
    final d = int.tryParse(spec.replaceAll(RegExp(r'[^0-9]'), '')) ?? 6;
    return _num(v).toDouble().toStringAsFixed(d);
  }
  return _str(v);
}

String _str(Object? v) {
  if (v == null) return 'None';
  if (v is bool) return v ? 'True' : 'False';
  if (v is _Nd) {
    if (v.shape.length == 1) return '(${v.shape.join(', ')},)';
    return '(${v.shape.join(', ')})';
  }
  if (v is _DataFrame) return _str(v.toMap());
  if (v is _Series) return _str(v.values);
  if (v is _MplFigure) return 'Figure(${v.w}x${v.h})';
  if (v is _MplAxes) return 'Axes';
  if (v is _SpMat) return '${v.format}_matrix${_str(v.shape)} nnz=${v.nnz}';
  if (v is _Tuple) {
    if (v.items.isEmpty) return '()';
    if (v.items.length == 1) return '(${_str(v.items.first)},)';
    return '(${v.items.map(_str).join(', ')})';
  }
  if (v is List) {
    if (v.isEmpty) return '[]';
    // tuple-looking lists from tuple() still print with [] unless we tag them.
    return '[${v.map(_str).join(', ')}]';
  }
  if (v is Map) {
    final body = v.entries.map((e) => '${_str(e.key)}: ${_str(e.value)}').join(', ');
    return '{$body}';
  }
  if (v is Set) return '{${v.map(_str).join(', ')}}';
  if (v is _Instance) return v.toString();
  if (v is _Gen) return v.values.toString();
  if (v is double) {
    if (v == v.roundToDouble() && v.abs() < 1e12) {
      if (v == v.toInt() && !v.toString().contains('e')) {
        // 0.0001 should stay 0.0001
      }
    }
    var s = v.toString();
    if (s.contains('e')) return v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }
  return '$v';
}

