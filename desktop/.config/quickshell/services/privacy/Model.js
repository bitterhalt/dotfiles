.pragma library

function flag(value) {
    return value === true || value === "true" || value === 1 || value === "1"
}

function monitor(node) {
    const properties = node.properties || {}
    return flag(properties["stream.monitor"])
        || properties["media.category"] === "Monitor"
        || properties["media.category"] === "Manager"
        || properties["device.class"] === "monitor"
        || String(node.name || "").endsWith(".monitor")
}

function microphoneApplications(groups, activeState) {
    const names = new Set()
    for (const group of groups) {
        if (!group || group.state !== activeState)
            continue
        const source = group.source
        const target = group.target
        // Capture is an active connection from an audio source to an input stream,
        // not merely an available/default microphone or a playback stream.
        if (!source || !target || !source.audio || !target.audio
                || source.isStream || source.isSink || !target.isStream)
            continue
        const properties = target.properties || {}
        if (properties["media.class"] !== "Stream/Input/Audio"
                || monitor(source) || monitor(target))
            continue
        names.add(String(properties["application.name"]
            || properties["application.process.binary"]
            || target.description || target.nickname || target.name || "Application"))
    }
    return Array.from(names).sort((a, b) => a.localeCompare(b))
}
