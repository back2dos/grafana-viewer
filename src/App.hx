

class App extends View {
  static inline var KEY = 'grafana-report';

  @:state var report:Option<GrafanaReport> = load(window.localStorage.getItem(KEY)).toOption();

  function render() '
    <div class=${RESET.add(ROOT)}>
      <switch ${report}>
        <case ${Some(data)}>
          <ReportView data=${data} onOpen=${handleOpen}/>
        <case ${None}>
          <label>
            Open Report
            <input type="file" onchange=${e -> handleOpen(e.src.files)} />
          </label>
      </switch>
    </div>  
  ';

  function load(content) 
    return try {
      final ret = GrafanaReport.parse(content);
      window.localStorage.setItem(KEY, content);
      Success(ret);
    }
    catch (e) {
      Failure(Error.withData('Failed to parse report', content));
    }

  function handleOpen(files:FileList) 
    switch files[0] {
      case null:
      case f:
        read(f).next(load).handle(o -> switch o {
          case Success(r): 
            this.report = Some(r);
          case Failure(e): 
            console.error(e);
            window.alert(e.message);
        });
    }
  static inline var ROOT = css({
    width: '100%',
    height: '100%',
    background: '#222',
    color: '#ddd',
    fontFamily: 'system-ui',
    '&>label': {
      width: '100%',
      height: '100%',
      display: 'flex',

      justifyContent: 'center',
      alignItems: 'center',
      
      'input[type="file"]': {
        display: 'none',
      }
    }
  });

  static inline var RESET = css({
    ':root': {
      width: '100%',
      height: '100%',
      body: {
        width: '100%',
        height: '100%',
      },
      '*': {
        'overscroll-behavior': 'none',
        margin: 0,
        padding: 0,
        lineHeight: 1,
        boxSizing: 'border-box',
        userSelect: 'none',
        '&:focus': {
          outline: 'none',
        },
        '-webkit-tap-highlight-color': 'transparent',
      },
      'a': {
        textDecoration: 'none',
        color: 'inherit'
      },
      'button, input, textarea': {
        border: 'none',
        background: 'none',
        color: 'inherit',
        font: 'inherit',
      },
      'label, button': {
        cursor: 'pointer',
      },
      'ul, ol': {
        listStyle: 'none'
      }
    }
  });
}

function read(f:File) {
  return new Promise((resolve, reject) -> {
    final r = new FileReader();
    r.onerror = e -> reject(Error.withData('Failed to load file', e));
    r.onload = () -> resolve((r.result:String));
    r.readAsText(f);
    return r.abort;
  });
}