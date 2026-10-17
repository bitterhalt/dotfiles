import QtQuick
import QtTest
import "../Model.js" as Model

TestCase {
    name: "NetworkModel"

    function test_connected_access_point_wins_over_stronger_duplicate() {
        const connected = {name: "Home", connected: true, known: true, signalStrength: 0.2};
        const stronger = {name: "Home", connected: false, known: true, signalStrength: 0.9};
        for (const networks of [[connected, stronger], [stronger, connected]]) {
            const rows = Model.rows(networks);
            compare(rows.length, 1);
            compare(rows[0].connected, true);
            compare(rows[0].strength, 0.2);
            compare(Model.networkForSsid(networks, "Home"), connected);
        }
    }

    function test_display_and_action_use_same_strongest_access_point() {
        const weaker = {name: "Cafe", signalStrength: 0.3, security: 1};
        const stronger = {name: "Cafe", signalStrength: 0.8, security: 2};
        compare(Model.rows([weaker, stronger])[0].security, 2);
        compare(Model.networkForSsid([weaker, stronger], "Cafe"), stronger);
        compare(Model.networkForSsid([null, weaker], "Missing"), null);
    }

    function test_sort_and_skip_empty_ssids() {
        const rows = Model.rows([
            null, {name: ""},
            {name: "Available", signalStrength: 0.9},
            {name: "Saved", known: true, signalStrength: 0.2},
            {name: "Connected", connected: true, signalStrength: 0.1}
        ]);
        compare(rows.map(row => row.ssid), ["Connected", "Saved", "Available"]);
    }

    function test_ssids_are_not_object_property_names() {
        const rows = Model.rows([
            {name: "__proto__", signalStrength: 0.5},
            {name: "constructor", signalStrength: 0.4}
        ]);
        compare(rows.length, 2);
        compare(rows[0].ssid, "__proto__");
        compare(rows[1].ssid, "constructor");
    }
}
