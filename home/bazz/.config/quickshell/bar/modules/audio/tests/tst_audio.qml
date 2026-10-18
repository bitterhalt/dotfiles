import QtQuick
import QtQuick.Window
import QtTest
import ".."
import "../Model.js" as Model
import "../Profiles.js" as Profiles

Item {
    id: host
    width: 480
    height: 450

    Component { id: fixtureComponent; AudioFixture {} }
    Component { id: stateComponent; AudioPopupState {} }
    Component { id: popupComponent; AudioPopup {} }
    Component { id: profileComponent; ProfileFixture {} }

    TestCase {
        id: test
        name: "AudioPopup"
        when: windowShown
        property var fixture: null
        property var controls: null
        property var popup: null
        property var profiles: null

        function init() {
            failOnWarning(/TypeError|Binding loop/);
            fixture = createTemporaryObject(fixtureComponent, host);
            profiles = createTemporaryObject(profileComponent, host);
            controls = createTemporaryObject(stateComponent, host, {audioItem: fixture, profiles: profiles});
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
            if (profiles)
                profiles.destroy();
            wait(0);
            popup = null;
            controls = null;
            fixture = null;
            profiles = null;
        }

        function press(key, modifiers, text) {
            return controls.handleKey(key, modifiers || Qt.NoModifier, text || "");
        }

        function volumeRows(item, found) {
            for (const child of item.children || []) {
                if (child.objectName === "audioVolumeRow")
                    found.push(child);
                volumeRows(child, found);
            }
            return found;
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
            press(Qt.Key_Backtab); compare(controls.tabIndex, 3);
            press(Qt.Key_L, Qt.ShiftModifier); compare(controls.tabIndex, 0);
            press(Qt.Key_H, Qt.ShiftModifier); compare(controls.tabIndex, 3);
        }

        function test_ctrl_arrows_switch_tabs() {
            compare(controls.tabIndex, 0);
            press(Qt.Key_Right, Qt.ControlModifier); compare(controls.tabIndex, 1);
            press(Qt.Key_Left, Qt.ControlModifier); compare(controls.tabIndex, 0);
            press(Qt.Key_Left, Qt.ControlModifier); compare(controls.tabIndex, 3);
            press(Qt.Key_Right, Qt.ControlModifier); compare(controls.tabIndex, 0);
            press(Qt.Key_Right); compare(fixture.speakerAudio.volume, 0.55);
            press(Qt.Key_Right, Qt.ControlModifier); compare(fixture.speakerAudio.volume, 0.55);
            compare(controls.tabIndex, 1);
            press(Qt.Key_Return);
            verify(controls.contextOpen);
            press(Qt.Key_Left, Qt.ControlModifier);
            verify(!controls.contextOpen);
            compare(controls.tabIndex, 0);
            press(Qt.Key_Question, Qt.ShiftModifier, "?");
            verify(controls.helpOpen);
            press(Qt.Key_Right, Qt.ControlModifier);
            verify(!controls.helpOpen);
            compare(controls.tabIndex, 1);
            verify(!press(Qt.Key_Right, Qt.AltModifier));
            verify(!press(Qt.Key_Left, Qt.MetaModifier));
            compare(controls.tabIndex, 1);
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
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture, profileBackend: profileComponent});
            verify(popup !== null);
            const keyboard = findChild(popup, "audioKeyboard");
            const popupControls = findChild(popup, "audioPopupState");
            tryVerify(() => keyboard.activeFocus);
            keyClick(Qt.Key_Right);
            compare(fixture.speakerAudio.volume, 0.55);
            const slider = findChild(popup, "audioVolumeSlider");
            verify(slider !== null);
            compare(slider.value, 0.55);
            compare(slider.background.color, fixture.config.muted);
            const percent = findChild(popup, "audioVolumePercent");
            compare(percent.text, "55%");
            fixture.speakerAudio.volume = 1.5;
            compare(percent.text, "150%");
            verify(slider.x + slider.width < percent.x);
            keyClick(Qt.Key_Tab);
            compare(popupControls.tabIndex, 1);
            keyClick(Qt.Key_Tab, Qt.ShiftModifier);
            compare(popupControls.tabIndex, 0);
            keyClick(Qt.Key_Right, Qt.ControlModifier);
            compare(popupControls.tabIndex, 1);
            keyClick(Qt.Key_Left, Qt.ControlModifier);
            compare(popupControls.tabIndex, 0);
            const currentSlider = findChild(popup, "audioVolumeSlider");
            compare(currentSlider.background.color, fixture.config.muted);
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
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture, profileBackend: profileComponent});
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
            verify(findText(popup, "Config") !== null);
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
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture, profileBackend: profileComponent});
            const popupControls = findChild(popup, "audioPopupState");
            waitForPolish(host.Window.window);
            const twoDeviceHeight = popup.implicitHeight;
            verify(twoDeviceHeight < 250);
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

        function test_single_row_list_hides_selection_marker() {
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture, profileBackend: profileComponent});
            const popupControls = findChild(popup, "audioPopupState");
            popupControls.setTab(1);
            waitForPolish(host.Window.window);
            compare(popupControls.rows.length, 1);
            tryVerify(() => volumeRows(popup, []).length === 1);
            verify(!volumeRows(popup, [])[0].selected);
            popupControls.setTab(0);
            waitForPolish(host.Window.window);
            compare(popupControls.rows.length, 2);
            tryVerify(() => volumeRows(popup, []).length === 2);
            compare(volumeRows(popup, []).filter((row) => {
                return row.selected;
            }).length, 1);
        }

        function test_profile_parser_and_off_devices() {
            const cards = profiles.cards;
            compare(cards.length, 2);
            compare(cards[0].id, "alsa_card.hdmi");
            compare(cards[0].media, "Off");
            compare(cards[0].profiles[2].available, false);
            compare(cards[1].profiles[0].available, true);
            const arrayFormat = Profiles.parse(JSON.stringify([{name: "card", active_profile: {name: "off"},
                profiles: [{name: "off", description: "Off"}]}]));
            compare(arrayFormat[0].profiles[0].active, true);
            let rejected = false;
            try { Profiles.parse('{}'); } catch (error) { rejected = true; }
            verify(rejected);
            verify(Profiles.isCardEvent("Event 'change' on card #42"));
            verify(Profiles.isCardEvent("Event 'new' on server #4294967295"));
            verify(!Profiles.isCardEvent("Event 'change' on sink #12"));
            verify(!Profiles.isCardEvent("Event 'change' on sink-input #33"));
        }

        function test_profile_selection_and_unavailable_guard() {
            controls.setTab(3);
            compare(controls.rows.length, 2);
            press(Qt.Key_Return);
            compare(controls.profileCardKey, "alsa_card.hdmi");
            compare(controls.selectedRow.id, "off");
            controls.selectRow(2);
            press(Qt.Key_Return);
            compare(profiles.calls.length, 0);
            verify(controls.profileCardKey !== "");
            controls.selectRow(1);
            press(Qt.Key_Return);
            compare(profiles.calls[0].card, "alsa_card.hdmi");
            compare(profiles.calls[0].profile, "hdmi");
            compare(controls.profileCardKey, "");
            compare(controls.selectedRow.media, "Digital Stereo (HDMI)");
            press(Qt.Key_Return);
            compare(controls.selectedRow.id, "hdmi");
            controls.selectRow(0);
            press(Qt.Key_Return);
            compare(controls.selectedRow.media, "Off");
            compare(fixture.calls.length, 0);
        }

        function test_config_no_volume_actions_or_refresh_key() {
            controls.setTab(3);
            press(Qt.Key_M); press(Qt.Key_D); press(Qt.Key_Right);
            compare(fixture.calls.length, 0);
            verify(!press(Qt.Key_R));
            compare(profiles.calls.length, 0);
            press(Qt.Key_Return);
            profiles.changing = true;
            controls.selectRow(1);
            press(Qt.Key_Return);
            compare(profiles.calls.length, 0);
            profiles.changing = false;
            press(Qt.Key_Escape);
            compare(controls.profileCardKey, "");
            verify(!fixture.closed);
            press(Qt.Key_Escape);
            verify(fixture.closed);
        }

        function test_profile_card_hot_unplug() {
            controls.setTab(3);
            press(Qt.Key_Return);
            profiles.source = profiles.source.slice(1);
            tryCompare(controls, "profileCardKey", "");
            compare(controls.rows.length, 1);
        }

        function test_popup_config_backend_lifecycle() {
            popup = createTemporaryObject(popupComponent, host, {audioItem: fixture, profileBackend: profileComponent});
            compare(findChild(popup, "audioProfiles"), null);
            const popupControls = findChild(popup, "audioPopupState");
            popupControls.setTab(3);
            const backend = findChild(popup, "audioProfiles");
            verify(backend !== null);
            verify(backend.active);
            waitForPolish(host.Window.window);
            const card = findText(popup, "HDMI");
            mouseClick(card, card.width / 2, card.height / 2);
            compare(popupControls.profileCardKey, "alsa_card.hdmi");
            popupControls.selectRow(1);
            popupControls.activateSelected();
            compare(backend.calls[0].profile, "hdmi");
            compare(popupControls.profileCardKey, "");
            popupControls.setTab(0);
            verify(!backend.active);
            popupControls.setTab(3);
            verify(backend.active);
        }
    }
}
