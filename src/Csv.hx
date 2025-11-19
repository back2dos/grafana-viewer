class Csv {
    static public function parse(content:String) {
        return parseLines(content.split('\n').map(StringTools.trim));
    }

    static public function parseLines(lines:Array<String>) {
        return {
            head: parseLine(lines.shift()),
            lines: lines.map(parseLine),
        }
    }

    static public function parseLine(line:String) {
        if (!line.contains('"')) return line.split(',');

        final ret = [];
        
        var cur = new StringBuf();
        var quoted = None;

        function flush() {
            ret.push(cur.toString());
            quoted = None;
            cur = new StringBuf();
        }
        
        for (c in line) 
            switch [c, quoted] {
                case ['"'.code, None]: quoted = Open;
                case ['"'.code, Open]: quoted = Closed;
                case [','.code, None | Closed]: flush();
                default: cur.addChar(c);
            }

        flush();

        return ret;
    }
}

enum abstract Quote(Int) {
    var None;
    var Open;
    var Closed;
}