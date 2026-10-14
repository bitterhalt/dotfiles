import QtQuick
import QtTest
import "../Languages.js" as Languages

TestCase {
    name: "TranslatorLanguages"

    function test_labels() {
        compare(Languages.label(""), "Auto-detect")
        compare(Languages.label("EN-GB"), "English (UK)")
        compare(Languages.label("FI"), "Finnish")
    }

    function test_choices_and_swap() {
        verify(Languages.targets().some(language => language.code === "FI"))
        verify(Languages.targets().some(language => language.code === "EN-US"))
        compare(Languages.targetFor("EN"), "EN-GB")
        compare(Languages.targetFor("PT"), "PT-PT")
    }
}
