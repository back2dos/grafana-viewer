import GrafanaReport;

class SeriesView extends View {
  @:attribute var diff:Bool;
  @:attribute var series:GrafanaSeries;
  @:attribute var color:String;
  @:attribute var min:Float;
  @:attribute var max:Float;
  @:attribute var average:Int;

  @:computed var entries:Vector<Float> = switch average {
    case 0: series.entries;
    case avg: 
      var entries = series.entries;
      var sum = .0;
      var total = 0;

      function add(i)
        switch entries[i] {
          case null:
          case v: 
            sum += v;
            total++;
        }

      function rem(i) 
        switch entries[i] {
          case null:
          case v:
            sum -=v;
            total--;
        }

      for (i in 0...avg) add(i);

      [for (i => e in entries) {
        rem(i - avg);
        add(i + avg);

        sum / total;
      }];
  }

  @:computed var slices:Vector<Vector<Float>> = switch diff {
    case false: [entries];
    case true:
      final half = entries.length >> 1;
      [entries.slice(0, half), entries.slice(half, entries.length)];
  }

  function render() '
    <svg class=${ROOT} viewBox="0 0 1000 1000" preserveAspectRatio="none">
      <for ${slice in slices}>
        <path d=${[for (i => v in slice) '${if (i == 0) 'M' else 'L'} ${1000 * i / slice.length},${1000 * (v - min) / (max - min)}'].join(' ')} stroke={color} />
      </for>
    </svg>
  ';

  static final ROOT = css({
    transform: 'scaleY(-1)',
    fill: 'none',
    strokeWidth: '3px',
    '&>path:nth-last-of-type(2)': {
      strokeDasharray: '3',
      opacity: .8,
    }
  });
}