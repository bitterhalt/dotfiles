import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false

    required property bool active
    required property string query
    required property string expression
    property string result: ""
    property int generation: 0
    readonly property bool busy: calculate.running || debounce.running
    signal resultReady

    onActiveChanged: refresh()
    onQueryChanged: refresh()
    onExpressionChanged: refresh()

    // qalc accepts * and /, not the typographic multiplication/division signs.
    function normalizeExpression(value): string {
        let out = value.replace(/×/g, "*").replace(/÷/g, "/");
        if (!/0[xX][0-9a-fA-F]/.test(out))
            out = out.replace(/(\d|\))\s*[xX]\s*(?=[\d(.])/g, "$1*");
        return out;
    }

    function refresh(): void {
        generation += 1;
        result = "";
        debounce.stop();
        if (active)
            debounce.restart();
    }

    Timer {
        id: debounce
        interval: 120
        onTriggered: {
            if (!root.active || calculate.running)
                return;
            calculate.generation = root.generation;
            calculate.command = ["qalc", "-t", root.normalizeExpression(root.expression)];
            calculate.running = true;
        }
    }

    Process {
        id: calculate
        property int generation: -1
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active || calculate.generation !== root.generation)
                    return;
                root.result = text.trim().split("\n")[0] || "";
                root.resultReady();
            }
        }
        onExited: exitCode => {
            if (calculate.generation === root.generation) {
                if (exitCode !== 0)
                    root.result = "";
            } else if (root.active) {
                debounce.restart();
            }
        }
    }
}
