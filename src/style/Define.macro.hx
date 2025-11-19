package style;

import style.Printer;
import tink.OnBuild.*;

private typedef ClassDecl = {
  final cls:String;
  final src:String;
  final css:String;
}

class Define {
  static inline var STYLED = ':styled';
  static public function getProduct(dotPath:String)
    return switch dotPath.split('.products.') {
      case [_, _.split('.')[0] => v]: Some(v);
      default: None;
    }  
    static function getString(t:Type)
      return switch t {
        case TInst(_.get().kind => KExpr(e), _): e.getString().sure();
        default: '';
      }

    static function init() {

      final 
        added = new Map(),
        output = [];

      after.exprs.whenever(t -> switch t {
        case TInst(cl, _) if (cl.get().meta.has(STYLED)):
          f -> e -> switch e.t {
            case TType(_.toString() => 'style.ClassName', [getString(_) => cls, getString(_) => src, getString(_) => css]):
              if (!added[cls]) {
                added[cls] = true;
                output.push(css);
              }
            default:
          }
        default: null;
      });

      after.types.after(EXPR_PASS, types -> {
        var out = Compiler.getOutput();
        out.withoutExtension().withExtension('css').saveContent(output.join('\n'));
      });
    }

  static function css(e:Expr) {

    if (Context.defined('display'))
      return 
        if (Context.containsDisplayPosition(e.pos)) {
          function drill(e:Expr) {
            return switch e.expr {
              case EDisplay(_):
                macro ($e:style.Define.Rule);
              case EObjectDecl(fields):
                for (f in fields)
                  if (Context.containsDisplayPosition(f.expr.pos)) return drill(f.expr);
                e;
              default: e;
            }
          }
          drill(e);
        }
        else macro (null:tink.domspec.ClassName);

    var explain = switch e {
      case macro @explain $v:
        e = v;
        true;
      default: false;
    }


    var cls = getName();

    switch Context.getLocalClass() {
      case null:
        throw 'not implemented';
      case _.get() => cl: 
        cl.meta.add(STYLED, [], (macro _).pos);
    }

    var css = Printer.printClass(e, '.$cls');

    var t = 
      'style.Define.ClassName'.asComplexType([
        TPExpr(macro $v{cls}), 
        TPExpr(macro $v{getSrc()}),
        TPExpr(macro $v{css})
      ])
    ;

    if (explain)
      e.pos.warning(css);

    return macro (cast $v{cls}:$t);
  }

  static function getSrc()
    return '${Context.getLocalModule()}:${Context.getPosInfos(Context.currentPos()).min}';

  static var counter = 0;

  static function getName()
    return #if dev getId() + '-' + #end (counter++).shortIdent();

  static function getId() {
    var id = switch Context.getLocalType() {
      case TInst(_.get() => cl, _): cl.name;
      default: throw 'not implemented';
    }

    if (id.endsWith('View'))
      id = id.substr(0, id.length - 4);

    switch Context.getLocalMethod() {
      case null | 'ROOT' | 'Style':
      case v: id = '$id-$v';
    }

    return id;
  }
}