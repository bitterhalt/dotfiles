import QtQuick
import QtTest
import ".."

Item {
    id: host
    width: 500
    height: 500

    QtObject {
        id: fixtureConfig
        property color surface: "#222222"
        property color borderColor: "#444444"
        property int popupRadius: 4
    }

    Component {
        id: panelComponent
        PopoutPanel {
            id: fixturePanel
            property var rows: []
            property bool extraRow: false
            config: fixtureConfig
            contentWidth: 260
            padding: 12
            spacing: 4
            visible: false

            Repeater {
                model: rows
                delegate: Item {
                    required property int index
                    objectName: "row" + index
                    width: parent.width
                    height: 32
                }
            }

            Item {
                visible: fixturePanel.extraRow
                height: fixturePanel.extraRow ? 32 : 0
                width: parent.width
            }
        }
    }

    TestCase {
        name: "PopoutPanelLayout"

        function test_first_open_sized_before_show() {
            const panel = createTemporaryObject(panelComponent, host);
            verify(panel !== null);
            panel.rows = [1, 2, 3, 4, 5];
            panel.prepareLayout();
            compare(panel.visible, false);
            compare(panel.implicitWidth, 260);
            compare(panel.implicitHeight, 24 + 5 * 32 + 4 * 4);
            for (let i = 0; i < 5; ++i) {
                const row = findChild(panel, "row" + i);
                compare(row.y, i * 36);
                compare(row.width, 236);
            }
        }

        function test_page_changes_settle_synchronously() {
            const panel = createTemporaryObject(panelComponent, host);
            for (const count of [7, 2, 5, 0, 3]) {
                panel.rows = Array.from({length: count}, (_, i) => i);
                panel.prepareLayout();
                compare(panel.implicitHeight, 24 + count * 32 + Math.max(0, count - 1) * 4);
            }
        }

        function test_conditional_recorder_row() {
            const panel = createTemporaryObject(panelComponent, host);
            panel.rows = [1, 2];
            panel.extraRow = true;
            panel.prepareLayout();
            compare(panel.implicitHeight, 24 + 3 * 32 + 2 * 4);
            panel.extraRow = false;
            panel.prepareLayout();
            compare(panel.implicitHeight, 24 + 2 * 32 + 4);
        }
    }
}
