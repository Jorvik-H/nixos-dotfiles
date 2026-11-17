import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  // Only watch when running under Mango
  property bool active: true

  // monitor name -> array of { state, clients }, where index 0 is tag 1
  // state: 0 = none, 1 = active, 2 = urgent
  property var tags: ({})
  property string focusedMonitor: ""

  property string lastJson: ""

  function tagsFor(name) {
    return tags[name] || [];
  }

  function parse(text) {
    var data;

    try {
      data = JSON.parse(text);
    } catch (e) {
      return;
    }

    var mons = data.monitors || [];
    var out = {};
    var focused = "";

    for (var i = 0; i < mons.length; i++) {
      var m = mons[i];
      var src = m.tags || [];
      var list = [];

      for (var j = 0; j < src.length; j++) {
        var t = src[j];

        list[t.index - 1] = {
          state: t.is_urgent ? 2 : (t.is_active ? 1 : 0),
          clients: t.client_count
        };
      }

      out[m.name] = list;

      if (m.active)
        focused = m.name;
    }

    var json = JSON.stringify([out, focused]);
    if (json === lastJson)
      return;

    lastJson = json;
    tags = out;
    focusedMonitor = focused;
  }

  function refresh() {
    if (active && !getProc.running)
      getProc.running = true;
  }

  // One-shot read of the current state
  Process {
    id: getProc
    command: ["mmsg", "get", "all-monitors"]

    stdout: StdioCollector {
      onStreamFinished: root.parse(this.text)
    }
  }

  // Any output from the watcher just means "something changed, read again"
  Process {
    running: root.active
    command: ["stdbuf", "-oL", "mmsg", "watch", "all-monitors"]

    stdout: SplitParser {
      onRead: line => debounce.restart()
    }
  }

  Timer {
    id: debounce
    interval: 50
    onTriggered: root.refresh()
  }

  // Fallback in case the watcher misses an event
  Timer {
    interval: 2000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
