import QtQuick
import QtTest
import "../Model.js" as Model

TestCase {
    name: "BluetoothModel"

    function test_trusted_state_and_sorting() {
        const rows = Model.rows([
            {address: "u", name: "Unpaired", paired: false, connected: false, trusted: false},
            {address: "t", name: "Trusted paired", paired: true, connected: false, trusted: true},
            {address: "p", name: "Paired", paired: true, connected: false, trusted: false},
            {address: "c", name: "Connected", paired: true, connected: true, trusted: true},
            null
        ])

        compare(rows.length, 4)
        compare(rows.map(row => row.address), ["c", "p", "t", "u"])
        compare(rows[0].trusted, true)
        compare(rows[2].trusted, true)
        compare(rows[1].trusted, false)
        compare(rows[3].trusted, false)
    }

    function test_missing_trust_defaults_false() {
        compare(Model.row({address: "device", paired: true}).trusted, false)
    }

    function test_names_and_address_fallback() {
        const row = Model.row({address: "AA:BB", trusted: true})
        compare(row.name, "AA:BB")
        compare(row.address, "AA:BB")
        compare(row.trusted, true)
    }

    function test_connected_unpaired_is_not_trust_togglable() {
        const row = Model.row({address: "AA:BB", connected: true, paired: false, trusted: false})
        compare(row.connected, true)
        compare(row.paired, false)
        compare(row.trusted, false)
    }
}
