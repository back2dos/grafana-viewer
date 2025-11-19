class App extends View {
  @:state var report:Option<GrafanaReport> = None;
  function render() '
    <div class=${RESET.add(ROOT)}>
      <switch ${report}>
        <case ${Some(data)}>
          <ReportView data=${data} />
        <case ${None}>
          <input type="file" onchange=${e -> switch e.src.files[0] {
            case null:
            case f:
              read(f).next(content -> GrafanaReport.parse.bind(content).catchExceptions()).handle(o -> switch o {
                case Success(r): 
                  this.report = Some(r);
                case Failure(e): 
                  console.error(e);
                  window.alert(e.message);
              });
          }} />
      </switch>
    </div>  
  ';

  static inline var ROOT = css({
    width: '100%',
    height: '100%',
    background: '#333',
    color: '#ddd',
    fontFamily: 'system-ui',
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