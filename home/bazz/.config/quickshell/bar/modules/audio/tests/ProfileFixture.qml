import QtQuick
import "../Profiles.js" as Profiles

Item {
    id: root
    objectName: "audioProfiles"
    property bool active: false
    property bool loading: false
    property bool changing: false
    property string errorText: ""
    property var calls: []
    property var source: [
        {name: "alsa_card.hdmi", properties: {"device.description": "HDMI"}, active_profile: "off", profiles: {
            off: {description: "Off", available: "yes"},
            hdmi: {description: "Digital Stereo (HDMI)", available: "yes"},
            unplugged: {description: "Digital Stereo (HDMI 2)", available: "no"}
        }},
        {name: "bluez_card.headset", properties: {"device.description": "Headset"}, active_profile: "aac", profiles: {
            aac: {description: "A2DP (AAC)", available: "unknown"},
            sbc: {description: "A2DP (SBC)", available: "yes"},
            off: {description: "Off", available: "yes"}
        }}
    ]
    readonly property var cards: Profiles.parse(JSON.stringify(source))
    signal profileApplied(string cardName)

    function refresh() { calls = calls.concat([{action: "refresh"}]); }
    function setProfile(cardName, profileName) {
        calls = calls.concat([{action: "profile", card: cardName, profile: profileName}]);
        source = source.map(card => Object.assign({}, card,
            card.name === cardName ? {active_profile: profileName} : {}));
        profileApplied(cardName);
    }
}
