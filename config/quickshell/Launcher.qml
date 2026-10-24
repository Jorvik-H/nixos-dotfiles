import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Scope {
  id: root

  property bool open: false
  property string query: ""
  property int selected: 0

  // Which monitor's bar shows the launcher (set when it opens)
  property string monitorName: ""

  property var matches: rank(query)
  property var best: matches.length > 0 ? matches[Math.min(selected, matches.length - 1)] : null

  onQueryChanged: selected = 0

  onOpenChanged: {
    if (!open) {
      query = "";
      selected = 0;
    }
  }

  // Best matches first: exact name, name prefix, word prefix, name substring, description
  function rank(q) {
    q = q.trim().toLowerCase();
    if (q === "")
      return [];

    var list = DesktopEntries.applications.values;
    var scored = [];

    for (var i = 0; i < list.length; i++) {
      var e = list[i];
      if (e.noDisplay)
        continue;

      var name = e.name.toLowerCase();
      var score = -1;

      if (name === q) {
        score = 0;
      } else if (name.indexOf(q) === 0) {
        score = 1;
      } else if (name.indexOf(" " + q) !== -1) {
        score = 2;
      } else if (name.indexOf(q) !== -1) {
        score = 3;
      } else {
        var extra = ((e.genericName || "") + " " + (e.comment || "")).toLowerCase();
        if (extra.indexOf(q) !== -1)
          score = 4;
      }

      if (score >= 0)
        scored.push({ entry: e, score: score });
    }

    scored.sort(function(a, b) {
      if (a.score !== b.score)
        return a.score - b.score;
      if (a.entry.name.length !== b.entry.name.length)
        return a.entry.name.length - b.entry.name.length;
      return a.entry.name.localeCompare(b.entry.name);
    });

    return scored.map(function(s) {
      return s.entry;
    });
  }

  // Step through the other matches (1 = next, -1 = previous)
  function cycle(delta) {
    if (matches.length === 0)
      return;

    selected = (selected + delta + matches.length) % matches.length;
  }

  function launch(entry) {
    if (entry.runInTerminal) {
      var cmd = ["kitty"];
      for (var i = 0; i < entry.command.length; i++)
        cmd.push(entry.command[i]);
      Quickshell.execDetached(cmd);
    } else {
      entry.execute();
    }
  }

  function launchSelected() {
    if (!best)
      return;

    launch(best);
    open = false;
  }

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      // Remember the focused monitor when opening, so the launcher stays put
      if (!root.open)
        root.monitorName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";

      root.open = !root.open;
    }
  }
}
