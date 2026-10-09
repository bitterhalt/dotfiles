.pragma library

function label(node) {
  return String(
    node.description || node.nickname || node.name || "Unknown device"
  );
}

function deviceRows(nodes, sink, defaultId) {
  var result = [];

  for (var i = 0; i < nodes.length; ++i) {
    var node = nodes[i];
    if (!node || node.isStream || !node.audio || node.isSink !== sink) continue;

    // PipeWire monitor sources are useful internally but are usually not
    // something you want to select as your microphone.
    if (!sink && String(node.name || "").endsWith(".monitor")) continue;

    result.push({
      id: Number(node.id),
      name: label(node),
      active: Number(node.id) === Number(defaultId),
    });
  }

  result.sort(function (a, b) {
    if (a.active !== b.active) return a.active ? -1 : 1;
    return a.name.localeCompare(b.name);
  });

  return result;
}

function playbackStreams(nodes) {
  var result = [];

  for (var i = 0; i < nodes.length; ++i) {
    var node = nodes[i];

    if (!node || !node.isStream || !node.audio || !node.isSink)
      continue;

    result.push({
      id: Number(node.id),
      name: String(
        (node.properties && node.properties["application.name"])
        || node.description
        || node.nickname
        || node.name
        || "Application"
      ),
      media: String(
        (node.properties && (
          node.properties["media.name"]
          || node.properties["media.title"]
        ))
        || ""
      )
    });
  }

  result.sort(function (a, b) {
    return a.name.localeCompare(b.name);
  });

  return result;
}
