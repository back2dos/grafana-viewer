package tools;

import tink.OnBuild;

function output() {
  OnBuild.after.types.whenever(_ -> {
    final output = Compiler.getOutput();
    Sys.command('npx', ['esbuild', '--minify', output, '--outfile=$output', '--allow-overwrite', '--charset=utf8', '--tree-shaking=true']);
  });
}