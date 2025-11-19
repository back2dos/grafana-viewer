package style;

@:forward
abstract Printer(StringBuf) {
  inline function new() this = new StringBuf();

  inline function out(s:String)
    #if dev
      this.add('\n$s')
    #else
      this.add(s)
    #end
  ;

  static final conditions:haxe.DynamicAccess<Option<String>> = {
  }

  function render(e, selector:String, indent:String, rec, ?inAtRule) {
    var selectorAdded = false,
        children = [],
        atRules = [];

    function process(e:Expr)
      switch e.expr {
        case EBlock([]):
        case EObjectDecl(fields):

          for (f in fields) {
            function emit(v) {
              if (!selectorAdded) {
                selectorAdded = true;
                out('${indent.substr(1)}$selector${#if dev ' ' #else '' #end}{');
              }

              var s = value(Context.typeExpr(v));
              var name:String = switch f.field {
                case 'content':
                if (!s.contains('attr')) s = '"$s"';
                  f.field;
                case 'css':
                  out(s);
                  return;
                case other:
                  if (f.quotes == Quoted) f.field
                  else styleProp(f.field) ?? {
                    Context.typeof(macro @:pos(fieldPos(f)) ({}:tink.domspec.Style).$other);// this will throw, hopefully with a nice error
                    '';
                  }
              }

              out('$indent$name:${#if dev " " #else "" #end}$s;');
            }

            var atRule = ~/^@[\w-]+/;

            if (atRule.match(f.field.trim()))
              if (inAtRule)
                fieldPos(f).error('Cannot nest at-rules');
              else switch atRule.matched(0) {
                case '@media' | '@supports':
                  atRules.push({
                    rule: f.field,
                    expr: f.expr,
                  });
                  continue;
                case '@font-face':
                  children.push({ expr: f.expr, selector: '@font-face' });
                  continue;
                case v:
                  fieldPos(f).error('Unsupported $v');
              }

            switch f.expr {
              case { expr: EBlock([]) | EObjectDecl([]) }:
              case { expr: EObjectDecl(_) }:
                var field = f.field;
                if (f.quotes == Quoted) 
                  switch MacroStringTools.formatString(field, fieldPos(f)) {
                    case { expr: EConst(CString(_)) }:
                    case e: field = value(Context.typeExpr(e));
                  }
                children.push({
                  expr: f.expr,
                  selector:
                    if (f.field.startsWith('if'))
                      switch conditions[f.field] {
                        case null:
                          fieldPos(f).error('unknown condition ${f.field}');
                        case None:
                          continue;
                        case Some(''):
                          process(f.expr);
                          continue;
                        case Some(v): '$v $selector';
                      }
                    else switch field.split('&') {
                      case [single]:
                        if (f.quotes != Quoted)
                          if (single.charAt(0) == single.charAt(0).toUpperCase())
                            single = '.' + value(Context.typeExpr(macro @:pos(fieldPos(f)) @:privateAccess $i{single}.ROOT));
                          else
                            if (!tink.domspec.Macro.tags.exists(single)) fieldPos(f).error('Unknown tag: $single. If it is truly what you mean, use `\'$single}\' and report the missing tag on https://github.com/haxetink/tink_domspec/issues');
                        
                        switch '$selector $single'.trim().split(':root') {
                          case [v]: v;
                          case [_, '']: ':root';
                          case v: v[1].trim();
                        }
                      case parts: parts.join(selector);
                    }
                });
              case { pos: pos, expr: EConst(CString(v, SingleQuotes)) }:
                emit(MacroStringTools.formatString(v, pos));// right?
              case e:
                emit(e);
            }
          }

        default:
      }

    process(e);

    if (selectorAdded) out('${indent.substr(1)}}');

    for (c in children) rec(c.expr, c.selector);

    for (a in atRules) {
      out('${a.rule}{');
      render(a.expr, selector, indent + #if dev '\t' #else '' #end, rec, true);
      out('}');
    }
  }

  function value(t:TypedExpr):String
    return 
      if (t == null) null 
      else switch t.expr {
        case TField(_, FStatic(cl, _.get() => f)):
          if (f.isFinal) value(f.expr());
          else t.pos.error('${cl.toString()}.${f.name} should be constant (final or inline)');
        case TConst(c):
          switch c {
            case TString(s) | TFloat(s): s;
            case TInt(i): '$i';
            case TNull: null;
            default: t.pos.error('String, Float or Int constant expected, found $c');
          }
        case TParenthesis(e) | TCast(e, null): value(e);
        case TBinop(OpAdd, v1, v2): value(v1) + value(v2);
        case TBinop(_):
          try t.eval() + ''
          catch (e:haxe.macro.Error) e.pos.error(e.message)
          catch (e) t.pos.error(e);
        default:
          t.pos.error('Constant expected, found ' + t.toString(true));
      }
    

  static public function printClass(e:Expr, selector:String) {
    var p = new Printer();

    function rec(e, selector)
      p.render(e, selector, #if dev '\t' #else '' #end, rec);

    rec(e, selector);

    return p.toString();
  }

  static var styleProps = null;

  static function styleProp(name) {
    styleProps ??= {
      var ret = new Map();

      for (t in ['Style', 'Style.SvgStyle'])
        switch Context.getType('tink.domspec.$t').reduce() {
          case TAnonymous(_.get().fields => fields):
            for (f in fields) ret[f.name] = camelToKebab(f.name);
          default: throw 'something went wrong';
        }

      ret;
    }

    return styleProps[name];
  }
}

private function camelToKebab(s:String) {// yum!
  var lower = s.toLowerCase();
  return
    if (lower == s) s;
    else {
      var buf = new StringBuf();
      for (i => c in lower) {
        if (s.fastCodeAt(i) != c) buf.addChar('-'.code);
        buf.addChar(c);
      }
      buf.toString();
    }
}

private function fieldPos(o:ObjectField) {
  return switch (cast o).name_pos {
    case null: o.expr.pos;
    case v:
      if (Context.getPosInfos(v).max > 0) v;
      else {
        var ret = Context.getPosInfos(o.expr.pos);
        ret.min = ret.min - 2 - o.field.length;
        ret.max = ret.min + o.field.length;
        Context.makePosition(ret);
      }
  }
}