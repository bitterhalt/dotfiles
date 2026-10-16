import QtQuick
import QtQuick.Window
import QtTest
import ".."
import "../Model.js" as Model

Item {
    id: host
    width: 480
    height: 450

    Component { id: fixtureComponent; AudioFixture {} }
    Component { id: stateComponent; AudioPopupState {} }
    Component { id: popupComponent; AudioPopup {} }

    TestCase {
        id: test
        name: "AudioPopup"
        when: windowShown
        property var fixture: null
        property var controls: null
        property var popup: null

        function init() {
            failOnWarning(/TypeError|Binding loop/);
            fixture = createTemporaryObject(fixtureComponent, host);
            controls = createTemporaryObject(stateComponent, host, {audioItem: fixture});
            verify(fixture !== null && controls !== null);
            controls.closeRequested.connect(() => fixture.closePopup());
        }

        function cleanup() {
            // Destroy views before their fake backing objects, as the shell does.
            if (popup)
                popup.destroy();
            if (controls)
                controls.destroy();
            wait(0);
            if (fixture)
                fixture.destroy();
            wait(0);
            popup = null;
            controls = null;
            fixture = null;
        }

        function press(key, modifiers, text) {
            return controls.handleKey(key, modifiers || Qt.NoModifier, text || "");
        }

        function test_models() {
            compare(fixture.outputRows.length, 2);
            compare(fixture.inputRows.length, 1);
            compare(fixture.streamRows.length, 1);
            compare(fixture.outputRows[0].id, 1);
            compare(fixture.streamRows[0].kind, "playback");
            const monitor = {id: 5, name: "speaker.monitor", audio: {}, isSink: false};
            compare(Model.deviceRows([monitor], false, -1).length, 0);
        }

        function test_tab_navigation() {
            compare(controls.tabIndex, 0);
            press(Qt.Key_Tab); compare(controls.tabIndex, 1);
            press(Qt.Key_Tab, Qt.ShiftModifier); compare(controls.tabIndex, 0);
            press(Qt.Key_Backtab); compare(controls.tabIndex, 2);
            press(Qt.Key_L, Qt.ShiftModifier); compare(controls.tabIndex, 0);
            press(Qt.Key_H, Qt.ShiftModifier); compare(controls.tabIndex, 2);
        }

        function test_volume_and_mute() {
            press(Qt.Key_Right); compare(fixture.speakerAudio.volume, 0.55);
            press(Qt.Key_H); compare(fixture.speakerAudio.volume, 0.5);
            press(Qt.Key_Down); compare(controls.selectedRow.id, 2);
            press(Qt.Key_M); compare(fixture.headsetAudio.muted, true);
            controls.setTab(1);
            press(Qt.Key_L); compare(fixture.micAudio.volume, 0.45);
            press(Qt.Key_M); compare(fixture.micAudio.muted, true);
            controls.setTab(2);
            press(Qt.Key_Left); compare(fixture.streamAudio.volume, 0.55);
            press(Qt.Key_M); compare(fixture.streamAudio.muted, true);
            fixture.streamAudio.volume = 1.49;
            press(Qt.Key_Right); compare(fixture.streamAudio.volume, 1.5);
            fixture.streamAudio.volume = 0.01;
            press(Qt.Key_Left); compare(fixture.streamAudio.volume, 0);
        }

        function test_default_selection_survives_reordering() {
            controls.selectRow(1);
            compare(controls.selectedRow.id, 2);
            press(Qt.Key_D);
            compare(fixture.outputId, 2);
            compare(controls.selectedRow.id, 2);
            compare(controls.selectedIndex, 0);
        }

        function test_input_default_and_playback_options() {
            controls.setTab(1);
            press(Qt.Key_D);
            compare(fixture.calls.length, 0);
            controls.setTab(2);
            const count = fixture.calls.length;
            press(Qt.Key_D);
            compare(fixture.calls.length, count);
            press(Qt.Key_Return);
            compare(controls.contextActions.length, 1);
            compare(controls.contextActions[0].action, "mute");
        }

        function test_options_and_escape() {
            press(Qt.Key_Return);
            verify(controls.contextOpen);
            press(Qt.Key_Return);
            compare(fixture.speakerAudio.muted, true);
            verify(!controls.contextOpen);
            controls.selectRow(1);
            press(Qt.Key_C);
            press(Qt.Key_Down);
            press(Qt.Key_Return);
            compare(fixture.calls[fixture.calls.length - 1].action, "output");
            press(Qt.Key_C);
            press(Qt.Key_Escape);
            verify(!controls.contextOpen);
            verify(!fixture.closed);
            press(Qt.Key_Escape);
            verify(fixture.closed);
        }

        function test_help_and_unsupported_keys() {
            press(Qt.Key_Question, Qt.ShiftModifier, "?");
            verify(controls.helpOpen);
            press(Qt.Key_M);
            compare(fixture.calls.length, 0);
            press(Qt.Key_Escape);
            verify(!controls.helpOpen);
            verify(!fixture.closed);
            verify(!press(Qt.Key_Q));
            verify(!press(Qt.Key_9));
            verify(!press(Qt.Key_M, Qt.ControlModifier));
            compare(fixture.calls.length, 0);
        }

        function test_hotplug_and_empty_lists() {
            controls.selectRow(1);
            press(Qt.Key_Return);
            verify(controls.contextOpen);
            fixture.allNodes = [fixture.speaker, fixture.mic];
            verify(!controls.contextOpen);
            compare(controls.selectedRow.id, 1);
            controls.setTab(2);
            compare(controls.selectedIndex, -1);
            press(Qt.Key_M); press(Qt.Key_Right); press(Qt.Key_Return);
            compare(fixture.calls.length, 0);
        }

        function test_popup_keyboard_and_live_slider() {
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture});
            verify(popup !== null);
            const keyboard = findChild(popup, "audioKeyboard");
            const popupControls = findChild(popup, "audioPopupState");
            tryVerify(() => keyboard.activeFocus);
            keyClick(Qt.Key_Right);
            compare(fixture.speakerAudio.volume, 0.55);
            const slider = findChild(popup, "audioVolumeSlider");
            verify(slider !== null);
            compare(slider.value, 0.55);
            const percent = findChild(popup, "audioVolumePercent");
            compare(percent.text, "55%");
            fixture.speakerAudio.volume = 1.5;
            compare(percent.text, "150%");
            verify(slider.x + slider.width < percent.x);
            keyClick(Qt.Key_Tab);
            compare(popupControls.tabIndex, 1);
            keyClick(Qt.Key_Tab, Qt.ShiftModifier);
            compare(popupControls.tabIndex, 0);
            keyClick(Qt.Key_Escape);
            verify(fixture.closed);
        }

        function findText(item, value) {
            if (item.text === value)
                return item;
            for (const child of item.children || []) {
                const match = findText(child, value);
                if (match)
                    return match;
            }
            return null;
        }

        function test_popup_mouse_controls() {
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture});
            const keyboard = findChild(popup, "audioKeyboard");
            const popupControls = findChild(popup, "audioPopupState");
            tryVerify(() => keyboard.activeFocus);
            waitForPolish(host.Window.window);
            const slider = findChild(popup, "audioVolumeSlider");
            mouseClick(slider, slider.width * 0.8, slider.height / 2);
            verify(fixture.speakerAudio.volume > 1);
            verify(keyboard.activeFocus);
            const playbackTab = findText(popup, "Playback");
            verify(playbackTab !== null);
            mouseClick(playbackTab, playbackTab.width / 2, playbackTab.height / 2);
            compare(popupControls.tabIndex, 2);
            const inputTab = findText(popup, "Inputs");
            mouseClick(inputTab, inputTab.width / 2, inputTab.height / 2);
            compare(popupControls.tabIndex, 1);
            waitForPolish(host.Window.window);
            keyClick(Qt.Key_D);
            compare(fixture.calls.filter(call => call.action === "input").length, 0);
            compare(findText(popup, "Config"), null);
            compare(findText(popup, "Tab"), null);
        }

        function test_default_action_visibility() {
            compare(controls.selectedRow.active, true);
            compare(controls.contextActions.length, 1);
            press(Qt.Key_D);
            compare(fixture.calls.length, 0);
            controls.selectRow(1);
            compare(controls.contextActions.length, 2);
            press(Qt.Key_Return);
            press(Qt.Key_Down);
            compare(controls.contextIndex, 1);
            fixture.setOutput(2);
            compare(controls.selectedRow.id, 2);
            compare(controls.contextActions.length, 1);
            compare(controls.contextIndex, 0);
        }

        function test_adaptive_height_and_scroll_limit() {
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture});
            const popupControls = findChild(popup, "audioPopupState");
            waitForPolish(host.Window.window);
            const twoDeviceHeight = popup.implicitHeight;
            verify(twoDeviceHeight < 300);
            popupControls.setTab(1);
            waitForPolish(host.Window.window);
            verify(popup.implicitHeight < twoDeviceHeight);
            popupControls.helpOpen = true;
            waitForPolish(host.Window.window);
            verify(popup.implicitHeight > twoDeviceHeight);
            popupControls.setTab(0);
            const many = [];
            for (let i = 0; i < 10; ++i)
                many.push({id: 10 + i, name: "Device " + i, audio: fixture.speakerAudio, isSink: true, isStream: false});
            fixture.allNodes = many;
            waitForPolish(host.Window.window);
            verify(popup.desiredBodyHeight > popup.maximumBodyHeight);
            verify(popup.implicitHeight <= popup.maximumBodyHeight + popup.chromeHeight + popup.padding * 2);
            popupControls.selectRow(9);
            const list = findChild(popup, "audioRows");
            tryVerify(() => list.contentY > 0);
        }
    }
}
