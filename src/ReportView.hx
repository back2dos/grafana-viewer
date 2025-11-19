import GrafanaReport;
import tink.pure.Dict;

class ReportView extends View {
  @:attribute function onOpen(files:FileList) {}
  @:attribute var data:GrafanaReport;
  @:state var diff = false;
  @:state var average = 0;
  @:computed var colors:Dict<GrafanaSeries, String> = [for (i => s in data.series) s => 'hsl(${360 * i / data.series.length}deg, 70%, 60%)'];

  function render() '
    <main class={ROOT}>
      <header>
        <label>
          <input type="range" max="${data.times.length >> 3}" value="${average}" oninput=${e -> this.average = Math.round(e.src.valueAsNumber)}/>{average}
        </label>
        
        <label>
          24h diff <input type="checkbox" onchange={e -> diff = e.src.checked} />
        </label>

        <label>
          Open New Report
          <input type="file" onchange={e -> onOpen(e.src.files)}/>
        </label>
      </header>
      <aside>
        <for {s in data.series}>
          <button onclick={e -> if (e.ctrlKey) data.toggle(s) else data.select(s)} data-active={data.selected.contains(s)}>
            <span style=${{ backgroundColor: colors[s] }}></span>${s.name}
          </button>
        </for>    
      </aside>
      <div>
        <for {s in data.selected}>
          <SeriesView key={s} series=${s} ${...data} average=${this.average} color={colors[s]} diff=${diff}/>
        </for>
      </div>
      <footer>
      </footer>
    </main>    
  ';

  static inline var ROOT = css({
    width: '100%',
    height: '100%',
    display: 'grid',
    gridTemplateRows: '60px 1fr 60px',
    gridTemplateColumns: '1fr 300px',

    '&>header': {
      gridColumn: '1 / -1',
      gridRow: 1,
      display: 'flex',
      columnGap: '30px',
      padding: '0 20px',
      alignItems: 'center',
      background: '#444',
      justifyContent: 'space-between',
      '&>label': {
        display: 'flex',
        columnGap: '10px',
        'input[type="file"]': {
          display: 'none',
        }
      }
    },

    '&>aside': {
      gridColumn: 2,
      gridRow: 2,
      background: "#333",
      padding: '10px',
      '&>button': {
        padding: '5px',
        width: '100%',
        color: '#888',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'start',
        columnGap: '10px',
        '&[data-active]': {
          color: 'white',
        },
        '&>span': {
          display: 'inline-block',
          width: '10px',
          height: '10px',
          borderRadius: '100%',
        }
      }
    },

    '&>div': {
      gridColumn: 1,
      gridRow: 2,
      position: 'relative',
      margin: '10px 10px 30px',
      '&>*': {
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
      }
    },

    '&>footer': {
      gridColumn: '1 / -1',
      gridRow: 3,
      background: '#444',
    }
  });
}
