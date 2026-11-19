pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "Languages.js" as Languages

Item {
    id: root

    required property var config
    required property var targetScreen
    property bool opened: false
    // Only language preferences survive closing; no text/history is retained.
    property string sourceLanguage: ""
    property string targetLanguage: "EN-GB"
    property bool preferencesReady: false
    property bool restoringPreferences: false

    function persistLanguages() {
        if (!preferencesReady || restoringPreferences)
            return;
        languagePreferences.setText(JSON.stringify({
            source: sourceLanguage,
            target: targetLanguage
        }));
    }

    onSourceLanguageChanged: persistLanguages()
    onTargetLanguageChanged: persistLanguages()

    PopupMotion {
        id: translatorMotion
        duration: 150
        shown: root.opened
        animationsEnabled: root.config.popupAnimations
        animationType: "fade"
    }

    function open() {
        opened = true;
    }
    function close() {
        opened = false;
    }
    function toggle() {
        opened = !opened;
    }

    LazyLoader {
        active: translatorMotion.surfaceVisible

        TranslatorWindow {
            config: root.config
            targetScreen: root.targetScreen
            popupMotion: translatorMotion
            sourceLanguage: root.sourceLanguage
            targetLanguage: root.targetLanguage
            onSourceLanguageChanged: root.sourceLanguage = sourceLanguage
            onTargetLanguageChanged: root.targetLanguage = targetLanguage
            onCloseRequested: root.close()
        }
    }

    FileView {
        id: languagePreferences
        objectName: "translatorLanguagePreferences"
        path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/quickshell-translator.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.restoringPreferences = true;
            try {
                const saved = JSON.parse(text());
                if (typeof saved.source === "string" && Languages.sources().some(language => language.code === saved.source))
                    root.sourceLanguage = saved.source;
                if (typeof saved.target === "string" && Languages.targets().some(language => language.code === saved.target))
                    root.targetLanguage = saved.target;
            } catch (error) {}
            root.restoringPreferences = false;
            root.preferencesReady = true;
        }
        onLoadFailed: root.preferencesReady = true
    }

    PopupIpcHandler {
        target: "translator"
        handleAction: action => root[action]()
    }
}
