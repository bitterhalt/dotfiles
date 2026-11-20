.pragma library

function isCardEvent(line) {
    return /\bon (card|server)\b/.test(String(line));
}

function parse(text) {
    const cards = JSON.parse(text);
    if (!Array.isArray(cards))
        throw new Error("Expected an audio card list");
    return cards.filter(card => card && typeof card.name === "string" && card.name !== "").map(card => {
        const active = typeof card.active_profile === "string" ? card.active_profile
            : (card.active_profile && card.active_profile.name) || "";
        const source = card.profiles || {};
        const profiles = (Array.isArray(source) ? source : Object.keys(source).map(name =>
            Object.assign({}, source[name], {name: name})))
            .filter(profile => profile && typeof profile.name === "string" && profile.name !== "")
            .map(profile => ({
                id: profile.name,
                card: card.name,
                name: profile.description || profile.name,
                kind: "profile",
                active: profile.name === active,
                available: profile.available !== "no" && profile.available !== false
            }));
        const current = profiles.find(profile => profile.active);
        return {
            id: card.name,
            name: (card.properties && card.properties["device.description"]) || card.name,
            kind: "card",
            media: current ? current.name : active || "Unknown profile",
            profiles: profiles
        };
    }).sort((a, b) => a.name.localeCompare(b.name));
}
