package style;

typedef Rule = Style & Style.SvgStyle & {
}

typedef ClassName<@:const Name, @:const Src, @:const Css> = tink.domspec.ClassName;

class Define {
    
  @:noUsing macro static public function css(e:Expr);

}