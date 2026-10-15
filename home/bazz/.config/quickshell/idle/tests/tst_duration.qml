import QtQuick
import QtTest
import "../Duration.js" as Duration

TestCase {
    name: "IdleDurations"

    function test_standard_intervals() {
        compare(Duration.parse("30s"), 30)
        compare(Duration.parse("30m"), 1800)
        compare(Duration.parse("2h"), 7200)
        compare(Duration.parse("1h 30m"), 5400)
        compare(Duration.parse("1.5m"), 90)
        compare(Duration.parse("0"), 0)
    }

    function test_invalid_intervals() {
        for (const value of ["", "30", "-1m", "never", "30m later", "169h", "0s"])
            compare(Duration.parse(value), -1)
    }

    function test_round_trip() {
        for (const seconds of [0, 30, 1700, 1800, 7200, 86400])
            compare(Duration.parse(Duration.format(seconds)), seconds)
    }

    function test_ordering() {
        compare(Duration.validate(1800, 1800, 7200), "")
        compare(Duration.validate(0, 1800, 7200), "")
        compare(Duration.validate(0, 0, 0), "")
        verify(Duration.validate(1800, 30, 7200) !== "")
        verify(Duration.validate(1800, 0, 30) !== "")
        verify(Duration.validate(-1, 1800, 7200) !== "")
    }
}
