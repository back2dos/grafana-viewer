class GrafanaReport implements Model {
    @:constant var times:Vector<Date>;
    @:constant var series:Vector<GrafanaSeries>;

    @:editable private var _selected:Vector<Bool> = [for (s in series) true];
    @:computed var selected:Vector<GrafanaSeries> = [for (i => selected in _selected) if (selected) series[i]];

    @:computed var min:Float = 0;
    @:computed var max:Float = selected.fold((s, result) -> Math.max(s.max, result), Math.NEGATIVE_INFINITY);

    public function toggle(target:GrafanaSeries, ?force:Bool) 
        this._selected = [for (i => s in series) if (s == target) force ?? !_selected[i] else _selected[i]];

    public function select(target:GrafanaSeries)
        this._selected = [for (s in series) s == target];

    static public function parse(content) {
        final csv = Csv.parse(content);

        return new GrafanaReport({
            times: [for (l in csv.lines) Date.fromString(l[0])],
            series: [for (i => n in csv.head) 
                if (i > 0) {
                    final entries:Vector<Float> = [for (l in csv.lines) Std.parseFloat(l[i])];
                    ({ 
                        name: n, 
                        entries: entries, 
                        min: entries.fold(Math.min, Math.POSITIVE_INFINITY),
                        max: entries.fold(Math.max, Math.NEGATIVE_INFINITY),
                     }:GrafanaSeries);
                }
            ]
        });
    }
}

typedef GrafanaSeries = {
    final name:String;
    final entries:Vector<Float>;
    final max:Float;
    final min:Float;
}