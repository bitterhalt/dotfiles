import QtQuick
import QtTest
import "../BatteryWarning.js" as BatteryWarning

TestCase {
    name: "BluetoothBatteryWarning"

    function step(previous, percent, low, critical, rearm) {
        return BatteryWarning.evaluate(previous, percent / 100,
            low === undefined ? 20 : low,
            critical === undefined ? 10 : critical,
            rearm === undefined ? 5 : rearm)
    }

    function test_thresholds_and_deduplication() {
        let result = step(null, 50)
        compare(result.warning, "")
        result = step(result.state, 20)
        compare(result.warning, "low")
        result = step(result.state, 19)
        compare(result.warning, "")
        result = step(result.state, 10)
        compare(result.warning, "critical")
        result = step(result.state, 5)
        compare(result.warning, "")
    }

    function test_initial_critical_only() {
        const result = step(null, 5)
        compare(result.warning, "critical")
        compare(step(result.state, 5).warning, "")
        compare(step(result.state, 18).warning, "")
    }

    function test_hysteresis_rearms_low_warning() {
        let result = step(null, 20)
        result = step(result.state, 21)
        result = step(result.state, 20)
        compare(result.warning, "")
        result = step(result.state, 24)
        result = step(result.state, 20)
        compare(result.warning, "")
        result = step(result.state, 25)
        compare(result.warning, "")
        result = step(result.state, 20)
        compare(result.warning, "low")
    }

    function test_critical_rearms_independently() {
        let result = step(null, 10)
        result = step(result.state, 14)
        result = step(result.state, 10)
        compare(result.warning, "")
        result = step(result.state, 15)
        result = step(result.state, 10)
        compare(result.warning, "critical")
    }

    function test_zero_disables_each_threshold() {
        compare(step(null, 0, 0, 0).warning, "")
        compare(step(null, 15, 0, 10).warning, "")
        compare(step(null, 10, 0, 10).warning, "critical")
        compare(step(null, 5, 20, 0).warning, "low")
    }

    function test_live_threshold_changes_allow_testing() {
        let result = step(null, 65)
        compare(result.warning, "")
        result = step(result.state, 65, 70, 10)
        compare(result.warning, "low")
        result = step(result.state, 65, 70, 10)
        compare(result.warning, "")
        result = step(result.state, 65, 80, 70)
        compare(result.warning, "critical")
    }

    function test_unknown_and_invalid_values_are_ignored() {
        for (const battery of [undefined, null, NaN, Infinity, -0.1, 1.1, "0.1"])
            compare(BatteryWarning.evaluate(null, battery, 20, 10, 5), null)
        compare(step(null, 0).warning, "critical")
        compare(step(null, 100).warning, "")
    }

    function test_editing_one_threshold_does_not_repeat_the_other_warning() {
        let result = step(null, 8)
        compare(result.warning, "critical")
        result = step(result.state, 8, 70, 10)
        compare(result.warning, "")
        result = step(null, 18)
        compare(result.warning, "low")
        result = step(result.state, 18, 20, 5)
        compare(result.warning, "")
    }

    function test_device_states_are_independent() {
        const mouse = step(null, 20)
        const headset = step(null, 20)
        compare(mouse.warning, "low")
        compare(headset.warning, "low")
        compare(step(mouse.state, 19).warning, "")
        compare(step(headset.state, 10).warning, "critical")
    }

    function test_transition_does_not_mutate_previous_state() {
        const previous = step(null, 20).state
        const result = step(previous, 10)
        compare(previous.critical, false)
        compare(result.state.critical, true)
    }
}
