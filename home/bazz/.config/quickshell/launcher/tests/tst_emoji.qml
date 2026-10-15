import QtQuick
import QtTest
import "../Emoji.js" as Emoji
import "../Scorer.js" as Scorer

TestCase {
    name: "LauncherEmoji"

    readonly property var entries: [
        {emoji: "❤️‍🔥", name: "heart on fire"},
        {emoji: "🧑‍🚒", name: "firefighter"},
        {emoji: "🎆", name: "fireworks"},
        {emoji: "🔥", name: "fire"},
        {emoji: "🐱", name: "cat"}
    ]

    function names(rows) { return rows.map(entry => entry.name) }

    function test_exact_first_and_stable_ties() {
        compare(names(Emoji.search(entries, "fire", 100)),
            ["fire", "firefighter", "fireworks", "heart on fire"])
        compare(Emoji.search(entries, "🔥", 100)[0].emoji, "🔥")
    }

    function test_order_independent_words() {
        compare(names(Emoji.search(entries, "fire heart", 100)), ["heart on fire"])
        compare(names(Emoji.search(entries, "  HEA   FI  ", 100)), ["heart on fire"])
        compare(Emoji.search(entries, "fire cat", 100).length, 0)
        compare(Emoji.search(entries, "fier", 100).length, 0)
        verify(Scorer.scoreEmoji("fire", "fire") > Scorer.scoreEmoji("firefighter", "fire"))
    }

    function test_sort_before_limit() {
        const many = []
        for (let i = 0; i < 110; ++i)
            many.push({emoji: "x" + i, name: "heart on fire " + i})
        many.push({emoji: "🔥", name: "fire"})
        const found = Emoji.search(many, "fire", 100)
        compare(found.length, 100)
        compare(found[0].name, "fire")
    }

    function test_empty_browse_recent_first() {
        compare(names(Emoji.browse(entries, [], 100)), names(entries))
        compare(names(Emoji.browse(entries, ["🐱", "🔥"], 100)),
            ["cat", "fire", "heart on fire", "firefighter", "fireworks"])
        compare(names(Emoji.browse(entries, ["missing", "🔥", "🔥"], 2)),
            ["fire", "heart on fire"])
        compare(Emoji.browse([], ["🔥"], 100).length, 0)
    }

    function test_history_validation_and_bound() {
        compare(Emoji.parseHistory("bad JSON"), [])
        compare(Emoji.parseHistory('{"history":["🔥"]}'), [])
        compare(Emoji.parseHistory('["🔥",null,"",42,"🔥","🐱"]'), ["🔥", "🐱"])
        const many = []
        for (let i = 0; i < 30; ++i)
            many.push("emoji" + i)
        compare(Emoji.normalizeHistory(many).length, 20)
        compare(Emoji.normalizeHistory(["🐱"].concat(["🔥", "🐱"])), ["🐱", "🔥"])
    }

    function test_app_and_binary_ranking_unchanged() {
        compare(Scorer.scoreApplication({name: "Firefox"}, "firefox"), 10000)
        compare(Scorer.scoreApplication({name: "Firefox"}, "fire"), 5000)
        compare(Scorer.scoreText("firefox", "firefox"), 10000)
        compare(Scorer.scoreText("firefox", "fire"), 5000)
    }
}
