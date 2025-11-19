function main() {
    Renderer.mount(js.Browser.document.body, '<App />');

    #if dev
    final source = new EventSource("/esbuild");

    source.addEventListener("change", () -> window.location.reload());

    window.addEventListener("beforeunload", () -> source.close());
    #end
}