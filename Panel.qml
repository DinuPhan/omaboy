import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "dinuphan.omaboy"
  ipcTarget: "dinuphan.omaboy"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color accent: Color.accent
  readonly property color surface: Color.popups.background
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Luminance detection so light/bright Omarchy themes get deep, high-contrast ink colors
  function colorChannelLuminance(value) {
    var channel = Number(value)
    if (!isFinite(channel)) return 0
    return channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4)
  }

  function colorLuminance(c) {
    return 0.2126 * colorChannelLuminance(c.r)
      + 0.7152 * colorChannelLuminance(c.g)
      + 0.0722 * colorChannelLuminance(c.b)
  }

  readonly property bool isLightTheme: colorLuminance(surface) >= 0.5
  readonly property color dim: alpha(foreground, isLightTheme ? 0.70 : 0.64)
  readonly property color cardBorderColor: alpha(foreground, isLightTheme ? 0.30 : 0.22)
  readonly property color cardFillColor: alpha(foreground, isLightTheme ? 0.065 : 0.07)

  // Live state from `8bitdo-micro-focus-switch status --json`
  property bool connected: false
  property bool serviceActive: false
  property string serviceMode: "inactive"
  property string deviceModel: "8BitDo Micro"
  property string devicePath: ""
  property string activeProfileName: "agy"
  property int activeTurn: 0
  property string activeWindowClass: ""
  property string activeWindowTitle: ""
  property var profilesMap: ({})
  property var profileNames: []
  property var globalCombos: []

  // UI state: "profile" shows per-app mapping; "omarchy" shows global L2 layer
  property string viewMode: setting("showOmarchyLayerFirst", false) ? "omarchy" : "profile"
  property string selectedProfileName: "agy"
  property string hoveredButtonKey: ""
  property string statusNotice: ""

  // Interactive Rebind Modal State
  property bool editingBinding: false
  property string editProfileTarget: "agy"
  property string editButtonTarget: "A"
  property string editButtonLabel: "A"
  property string editButtonColor: "#d97706"
  property string editKeyText: ""
  property string editDescText: ""
  property bool capturingKeypress: false

  readonly property int refreshIntervalMs: Math.max(2, Number(setting("refreshIntervalSec", 5))) * 1000

  // Theme-adaptive semantic colors (vivid pastels on dark themes, deep WCAG-AA inks on bright/white themes)
  readonly property string colShoulder: isLightTheme ? "#c2410c" : "#fab387"
  readonly property string colTrigger:  isLightTheme ? "#be123c" : "#f38ba8"
  readonly property string colDpad:     isLightTheme ? "#15803d" : "#a6e3a1"
  readonly property string colCenter:   isLightTheme ? "#1d4ed8" : "#89b4fa"
  readonly property string colBottom:   isLightTheme ? "#6d28d9" : "#cba6f7"
  readonly property string colFace:     isLightTheme ? "#b45309" : "#f9e2af"

  // Exact 16-button geometry matching Tauri GUI & keymap_diagram.svg (1200x520 virtual canvas)
  readonly property var buttonMetaList: [
    // Left column (top to bottom)
    { key: "L",      label: "L1",       color: root.colShoulder, side: "left",  cx: 474, cy: 232, e1x: 474, e1y: 80,  e2x: 340, e2y: 65,  tx: 290, ty: 65  },
    { key: "L2",     label: "L2",       color: root.colTrigger,  side: "left",  cx: 524, cy: 232, e1x: 524, e1y: 140, e2x: 355, e2y: 125, tx: 290, ty: 125 },
    { key: "UP",     label: "▲ UP",     color: root.colDpad,     side: "left",  cx: 489, cy: 306, e1x: 430, e1y: 225, e2x: 345, e2y: 185, tx: 290, ty: 185 },
    { key: "LEFT",   label: "◀ LEFT",   color: root.colDpad,     side: "left",  cx: 460, cy: 335, e1x: 380, e1y: 265, e2x: 345, e2y: 245, tx: 290, ty: 245 },
    { key: "SELECT", label: "- SELECT", color: root.colCenter,   side: "left",  cx: 542, cy: 294, e1x: 480, e1y: 295, e2x: 380, e2y: 305, tx: 290, ty: 305 },
    { key: "DOWN",   label: "▼ DOWN",   color: root.colDpad,     side: "left",  cx: 489, cy: 364, e1x: 430, e1y: 365, e2x: 360, e2y: 365, tx: 290, ty: 365 },
    { key: "RIGHT",  label: "▶ RIGHT",  color: root.colDpad,     side: "left",  cx: 518, cy: 335, e1x: 480, e1y: 405, e2x: 380, e2y: 425, tx: 290, ty: 425 },
    { key: "STAR",   label: "★ STAR",   color: root.colBottom,   side: "left",  cx: 556, cy: 378, e1x: 480, e1y: 455, e2x: 380, e2y: 485, tx: 290, ty: 485 },
    // Right column (top to bottom)
    { key: "R",      label: "R1",       color: root.colShoulder, side: "right", cx: 694, cy: 232, e1x: 694, e1y: 80,  e2x: 860, e2y: 65,  tx: 910, ty: 65  },
    { key: "R2",     label: "R2",       color: root.colTrigger,  side: "right", cx: 644, cy: 232, e1x: 644, e1y: 140, e2x: 845, e2y: 125, tx: 910, ty: 125 },
    { key: "START",  label: "+ START",  color: root.colCenter,   side: "right", cx: 614, cy: 294, e1x: 680, e1y: 225, e2x: 835, e2y: 185, tx: 910, ty: 185 },
    { key: "X",      label: "X",        color: root.colFace,     side: "right", cx: 672, cy: 300, e1x: 740, e1y: 255, e2x: 835, e2y: 245, tx: 910, ty: 245 },
    { key: "Y",      label: "Y",        color: root.colFace,     side: "right", cx: 636, cy: 336, e1x: 710, e1y: 315, e2x: 835, e2y: 305, tx: 910, ty: 305 },
    { key: "A",      label: "A",        color: root.colFace,     side: "right", cx: 710, cy: 336, e1x: 770, e1y: 350, e2x: 845, e2y: 365, tx: 910, ty: 365 },
    { key: "B",      label: "B",        color: root.colFace,     side: "right", cx: 672, cy: 374, e1x: 740, e1y: 405, e2x: 835, e2y: 425, tx: 910, ty: 425 },
    { key: "HOME",   label: "♥ HOME",   color: root.colBottom,   side: "right", cx: 600, cy: 378, e1x: 670, e1y: 455, e2x: 820, e2y: 485, tx: 910, ty: 485 }
  ]

  readonly property var quickKeyChips: [
    { label: "Space", value: "SPACE" },
    { label: "Enter", value: "ENTER" },
    { label: "Esc", value: "ESC" },
    { label: "Tab", value: "TAB" },
    { label: "Shift+Tab", value: "LEFTSHIFT+TAB" },
    { label: "Backspace", value: "BACKSPACE" },
    { label: "K (Play)", value: "K" },
    { label: "F (Full)", value: "F" },
    { label: "J (-10s)", value: "J" },
    { label: "L (+10s)", value: "L" },
    { label: "/ (Search)", value: "SLASH" },
    { label: "C (Sub)", value: "C" },
    { label: "M (Mute)", value: "M" },
    { label: "F9 (Whisper)", value: "F9" },
    { label: "Vol+", value: "VolumeUp" },
    { label: "Vol-", value: "VolumeDown" },
    { label: "PgUp", value: "PAGEUP" },
    { label: "PgDn", value: "PAGEDOWN" },
    { label: "Alt+Left", value: "LEFTALT+LEFT" },
    { label: "Super+F", value: "LEFTMETA+F" },
    { label: "Super+W", value: "LEFTMETA+W" },
    { label: "Super+Space", value: "LEFTMETA+SPACE" }
  ]

  readonly property var currentProfile: {
    if (profilesMap && selectedProfileName in profilesMap)
      return profilesMap[selectedProfileName]
    if (profilesMap && activeProfileName in profilesMap)
      return profilesMap[activeProfileName]
    return null
  }

  readonly property var currentButtons: currentProfile && currentProfile.buttons ? currentProfile.buttons : ({})
  readonly property var currentCombos: currentProfile && currentProfile.combos ? currentProfile.combos : []
  readonly property var displayedCombos: viewMode === "omarchy" ? globalCombos : currentCombos

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  function prettyAction(text, maxLen) {
    var s = String(text || "None")
    if (s === "" || s === "None") return "None"
    if (s.indexOf("exec:") === 0) s = "⚡ " + s.slice(5)
    s = s.replace(/^omarchy-launch-or-focus-webapp\s+/, "App: ")
    s = s.replace(/^omarchy-launch-or-focus\s+/, "Focus: ")
    s = s.replace(/^omarchy-shell\s+shell\s+toggle\s+/, "Toggle: ")
    s = s.replace(/LEFTMETA/g, "Super")
    s = s.replace(/LEFTSHIFT/g, "Shift")
    s = s.replace(/LEFTCTRL/g, "Ctrl")
    s = s.replace(/LEFTALT/g, "Alt")
    s = s.replace(/\+/g, " + ")
    var limit = maxLen || 22
    return s.length > limit ? s.slice(0, limit - 1) + "…" : s
  }

  function rawActionForButton(btnKey) {
    if (viewMode === "omarchy") {
      if (btnKey === "L2") return "HOLD (Modifier)"
      for (var i = 0; i < globalCombos.length; i++) {
        var gc = globalCombos[i]
        var btns = gc.buttons || []
        if (btns.length === 2 && (btns[0] === "L2" || btns[1] === "L2")) {
          var other = btns[0] === "L2" ? btns[1] : btns[0]
          if (other === btnKey) return String(gc.label || "None")
        }
      }
      return "None"
    }
    var b = currentButtons[btnKey]
    return b && b.label ? String(b.label) : "None"
  }

  function descForButton(btnKey) {
    if (viewMode === "omarchy") {
      if (btnKey === "L2") return "Dedicated Omarchy Fn Layer key"
      for (var i = 0; i < globalCombos.length; i++) {
        var gc = globalCombos[i]
        var btns = gc.buttons || []
        if (btns.length === 2 && (btns[0] === "L2" || btns[1] === "L2")) {
          var other = btns[0] === "L2" ? btns[1] : btns[0]
          if (other === btnKey) return String(gc.description || "")
        }
      }
      return ""
    }
    var b = currentButtons[btnKey]
    return b && b.description ? String(b.description) : ""
  }

  function tooltipForButton(meta) {
    var act = rawActionForButton(meta.key)
    var desc = descForButton(meta.key)
    var prefix = viewMode === "omarchy"
      ? (meta.key === "L2" ? "L2 (Omarchy Modifier)" : ("L2 + " + meta.label))
      : meta.label
    var main = prefix + "  ➔  " + (act === "None" ? "Unassigned (None)" : act)
    if (desc !== "") main += "\n“" + desc + "”"
    main += "\n(Click to change keybinding)"
    return main
  }

  function openRebindModal(meta) {
    if (viewMode === "omarchy") {
      if (meta.key === "L2") {
        statusNotice = "L2 is your dedicated Omarchy Hold Modifier. Click any other button to bind L2 + Button!"
        noticeClearTimer.restart()
        return
      }
      editProfileTarget = "global"
      editButtonTarget = "L2+" + meta.key
      editButtonLabel = "L2 + " + meta.label
    } else {
      editProfileTarget = selectedProfileName
      editButtonTarget = meta.key
      editButtonLabel = "[" + selectedProfileName.toUpperCase() + "]  " + meta.label
    }
    editButtonColor = meta.color
    var currentRaw = rawActionForButton(meta.key)
    editKeyText = (currentRaw === "None" || currentRaw === "HOLD (Modifier)") ? "" : currentRaw
    editDescText = descForButton(meta.key)
    capturingKeypress = false
    editingBinding = true
    Qt.callLater(function() { keyInput.forceActiveFocus() })
  }

  function openComboRebindModal(comboItem) {
    editProfileTarget = viewMode === "omarchy" ? "global" : selectedProfileName
    editButtonTarget = String(comboItem.combo || "L+R")
    editButtonLabel = "[" + editProfileTarget.toUpperCase() + "]  Combo " + editButtonTarget
    editButtonColor = root.colShoulder
    editKeyText = comboItem.label && comboItem.label !== "None" ? String(comboItem.label) : ""
    editDescText = String(comboItem.description || "")
    capturingKeypress = false
    editingBinding = true
    Qt.callLater(function() { keyInput.forceActiveFocus() })
  }

  function saveEditedBinding(clearToNone) {
    var keyVal = clearToNone ? "None" : String(editKeyText || "").trim()
    if (keyVal === "") keyVal = "None"
    var descVal = String(editDescText || "").trim()
    saveBindProcess.command = [
      "8bitdo-micro-focus-switch",
      "bind",
      editProfileTarget,
      editButtonTarget,
      "--key",
      keyVal,
      "--description",
      descVal
    ]
    statusNotice = "Saving " + editButtonTarget + " → " + keyVal + "…"
    editingBinding = false
    saveBindProcess.running = true
  }

  function startPhysicalKeyCapture() {
    if (captureBindProcess.running) return
    capturingKeypress = true
    var cmd = [
      "8bitdo-micro-focus-switch",
      "bind",
      editProfileTarget,
      editButtonTarget
    ]
    var descVal = String(editDescText || "").trim()
    if (descVal !== "") {
      cmd.push("--description")
      cmd.push(descVal)
    }
    captureBindProcess.command = cmd
    captureBindProcess.running = true
  }

  function cancelPhysicalKeyCapture() {
    if (captureBindProcess.running) {
      captureBindProcess.running = false
    }
    capturingKeypress = false
  }

  function refreshStatus(followActiveProfile) {
    if (statusProcess.running) return
    statusProcess.followActive = !!followActiveProfile
    statusProcess.running = true
  }

  function applyStatusJson(rawText, followActive) {
    var trimmed = String(rawText || "").trim()
    if (trimmed === "") return
    try {
      var data = JSON.parse(trimmed)
      root.connected = data.connected === true
      root.serviceActive = data.service_active === true
      root.serviceMode = String(data.service_mode || "inactive")
      if (data.devices && data.devices.length > 0) {
        root.deviceModel = String(data.devices[0].model || "8BitDo Micro")
        root.devicePath = String(data.devices[0].path || "")
      } else {
        root.deviceModel = "8BitDo Micro / Zero 2"
        root.devicePath = ""
      }
      root.activeProfileName = String(data.active_profile || "agy")
      root.activeTurn = Number(data.active_turn || 0)
      if (data.active_window) {
        root.activeWindowClass = String(data.active_window.class || "")
        root.activeWindowTitle = String(data.active_window.title || "")
      }
      root.globalCombos = data.global_combos || []
      root.profilesMap = data.profiles || ({})

      var names = []
      var preferred = ["agy", "youtube", "anki", "browser", "media"]
      for (var i = 0; i < preferred.length; i++) {
        if (preferred[i] in root.profilesMap) names.push(preferred[i])
      }
      for (var key in root.profilesMap) {
        if (key !== "global" && key !== "all" && key !== "factory" && key !== "supermemo" && names.indexOf(key) < 0)
          names.push(key)
      }
      root.profileNames = names

      if (followActive || !(root.selectedProfileName in root.profilesMap)) {
        root.selectedProfileName = root.activeProfileName
      }
      leaderCanvas.requestPaint()
    } catch (e) {
      // Ignore transient parse errors
    }
  }

  function cycleProfile(delta) {
    if (profileNames.length === 0) return
    var idx = profileNames.indexOf(selectedProfileName)
    if (idx < 0) idx = 0
    var nextIdx = ((idx + delta) % profileNames.length + profileNames.length) % profileNames.length
    selectedProfileName = profileNames[nextIdx]
    viewMode = "profile"
    leaderCanvas.requestPaint()
  }

  function reloadDaemon() {
    statusNotice = "Reloading profiles.toml…"
    reloadProcess.running = true
  }

  function editProfilesInEditor() {
    var cfg = (Quickshell.env("HOME") || "") + "/.config/8bitdo-micro/profiles.toml"
    Quickshell.execDetached(["omarchy-launch-editor", cfg])
    root.close()
  }

  function toggleDaemonService() {
    var action = root.serviceActive ? "restart" : "start"
    statusNotice = (action === "restart" ? "Restarting" : "Starting") + " daemon service…"
    Quickshell.execDetached(["systemctl", "--user", action, "8bitdo-micro-focus-switch.service"])
    refreshDelayTimer.restart()
  }

  Process {
    id: statusProcess
    property bool followActive: false
    running: false
    command: ["8bitdo-micro-focus-switch", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatusJson(text, statusProcess.followActive)
    }
  }

  Process {
    id: saveBindProcess
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.statusNotice = "✓ Saved binding & reloaded daemon!"
        noticeClearTimer.restart()
        root.refreshStatus(false)
      }
    }
  }

  Process {
    id: captureBindProcess
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.capturingKeypress = false
        root.editingBinding = false
        root.statusNotice = "✓ Captured key & reloaded daemon!"
        noticeClearTimer.restart()
        root.refreshStatus(false)
      }
    }
  }

  Process {
    id: reloadProcess
    running: false
    command: ["8bitdo-micro-focus-switch", "reload"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.statusNotice = "✓ Reloaded profiles.toml (SIGHUP)"
        noticeClearTimer.restart()
        root.refreshStatus(false)
      }
    }
  }

  Timer {
    id: refreshDelayTimer
    interval: 600
    repeat: false
    onTriggered: {
      root.statusNotice = ""
      root.refreshStatus(false)
    }
  }

  Timer {
    id: noticeClearTimer
    interval: 2600
    repeat: false
    onTriggered: root.statusNotice = ""
  }

  Timer {
    interval: root.refreshIntervalMs
    running: true
    repeat: true
    onTriggered: root.refreshStatus(!root.opened)
  }

  Component.onCompleted: root.refreshStatus(true)

  onOpenedChanged: {
    if (opened) {
      editingBinding = false
      capturingKeypress = false
      viewMode = setting("showOmarchyLayerFirst", false) ? "omarchy" : "profile"
      if (panelFlick) panelFlick.contentY = 0
      refreshStatus(true)
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    } else {
      cancelPhysicalKeyCapture()
      editingBinding = false
    }
  }

  onHoveredButtonKeyChanged: leaderCanvas.requestPaint()
  onViewModeChanged: leaderCanvas.requestPaint()
  onSelectedProfileNameChanged: leaderCanvas.requestPaint()
  onIsLightThemeChanged: leaderCanvas.requestPaint()

  IpcHandler {
    target: root.ipcTarget
    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function refresh() { root.refreshStatus(true) }
    function reload() { root.reloadDaemon() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰊴"
    active: root.connected
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.reloadDaemon()
      else if (buttonCode === Qt.MiddleButton) root.cycleProfile(1)
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: root.editingBinding ? keyInput : keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(840))
    contentHeight: panel.fittedContentHeight(column.implicitHeight + Style.space(28), Style.space(760))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      enabled: !root.editingBinding

      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.cycleProfile(dx)
        if (dy !== 0)
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(64), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
      }
      onActivateRequested: root.reloadDaemon()
      onCloseRequested: root.close()
      onTabRequested: function(direction) {
        root.viewMode = root.viewMode === "profile" ? "omarchy" : "profile"
      }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.reloadDaemon()
        else if (t === "l" || t === "L") root.viewMode = root.viewMode === "profile" ? "omarchy" : "profile"
        else if (t === "e" || t === "E") root.editProfilesInEditor()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        anchors.margins: Style.space(6)
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(16)

          // ---------- Top Header Bar ----------
          Item {
            width: parent.width
            implicitHeight: Style.space(48)

            Row {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(12)

              BorderSurface {
                width: Style.space(42)
                height: Style.space(42)
                radius: Style.cornerRadius
                color: root.connected ? root.alpha(root.accent, 0.16) : root.cardFillColor
                borderSpec: Border.flat(root.connected ? root.accent : root.cardBorderColor, 1.2)

                Text {
                  anchors.centerIn: parent
                  text: "󰊴"
                  color: root.connected ? root.accent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  text: "OmaBoy · " + (root.connected ? root.deviceModel : "Controller Standby")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Text {
                  text: (root.connected ? "🟢 Connected (uinput <1ms)" : "⚪ Bluetooth Sleeping")
                    + "   •   Active Window Profile: " + root.activeProfileName.toUpperCase()
                    + "   •   Click any button or card to rebind"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }

            // Right Header Quick Action Buttons
            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(8)

              Button {
                text: "↻ Reload"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                verticalPadding: Style.space(6)
                horizontalPadding: Style.space(12)
                onClicked: root.reloadDaemon()
              }

              Button {
                text: "✎ Edit TOML"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                verticalPadding: Style.space(6)
                horizontalPadding: Style.space(12)
                onClicked: root.editProfilesInEditor()
              }
            }
          }

          // ---------- Status Notice Toast ----------
          BorderSurface {
            visible: root.statusNotice !== ""
            width: parent.width
            implicitHeight: noticeLabel.implicitHeight + Style.space(14)
            color: root.alpha(root.accent, 0.15)
            borderSpec: Border.flat(root.alpha(root.accent, 0.55), 1.2)
            radius: Style.cornerRadius

            Text {
              id: noticeLabel
              anchors.centerIn: parent
              text: root.statusNotice
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          // ---------- Layer & Profile Selector Bar ----------
          Row {
            id: navBar
            width: parent.width
            spacing: Style.space(8)

            Button {
              text: "🕹️ App Keymap"
              selected: root.viewMode === "profile"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(7)
              horizontalPadding: Style.space(14)
              onClicked: root.viewMode = "profile"
            }

            Button {
              text: "⚡ Omarchy Layer (Hold L2)"
              selected: root.viewMode === "omarchy"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(7)
              horizontalPadding: Style.space(14)
              onClicked: root.viewMode = "omarchy"
            }

            Item {
              width: Style.space(10)
              height: 1
            }

            Repeater {
              model: root.profileNames

              Button {
                required property var modelData
                visible: root.viewMode === "profile"
                text: String(modelData).toUpperCase() + (String(modelData) === root.activeProfileName ? " •" : "")
                selected: root.viewMode === "profile" && String(modelData) === root.selectedProfileName
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                verticalPadding: Style.space(7)
                horizontalPadding: Style.space(12)
                onClicked: {
                  root.selectedProfileName = String(modelData)
                  root.viewMode = "profile"
                }
              }
            }
          }

          // ---------- Interactive Visual Controller Canvas (1200x540 Virtual Space) ----------
          BorderSurface {
            id: diagramContainer
            width: parent.width
            height: Math.round(width * (540 / 1200))
            radius: Style.cornerRadius
            color: root.alpha(root.foreground, root.isLightTheme ? 0.045 : 0.04)
            borderSpec: Border.flat(root.cardBorderColor, 1.2)

            readonly property real sx: width / 1200.0
            readonly property real sy: height / 540.0

            // Center 8BitDo Micro Controller Image
            Image {
              id: controllerImage
              x: 334 * diagramContainer.sx
              y: 185 * diagramContainer.sy
              width: 532 * diagramContainer.sx
              height: 329 * diagramContainer.sy
              source: Qt.resolvedUrl("assets/micro-controller.png")
              fillMode: Image.PreserveAspectFit
              smooth: true
            }

            // Leader Polylines & Glowing Pins Canvas
            Canvas {
              id: leaderCanvas
              anchors.fill: parent
              onWidthChanged: requestPaint()
              onHeightChanged: requestPaint()

              onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var sx = diagramContainer.sx
                var sy = diagramContainer.sy
                var list = root.buttonMetaList
                var light = root.isLightTheme

                for (var i = 0; i < list.length; i++) {
                  var m = list[i]
                  var isHov = (root.hoveredButtonKey === m.key)
                  ctx.save()
                  ctx.beginPath()
                  ctx.moveTo(m.cx * sx, m.cy * sy)
                  ctx.lineTo(m.e1x * sx, m.e1y * sy)
                  ctx.lineTo(m.e2x * sx, m.e2y * sy)
                  ctx.lineTo(m.tx * sx, m.ty * sy)
                  ctx.strokeStyle = m.color
                  ctx.globalAlpha = isHov ? 1.0 : (light ? 0.90 : 0.78)
                  ctx.lineWidth = isHov ? 3.2 : (light ? 2.1 : 1.7)
                  ctx.lineCap = "round"
                  ctx.lineJoin = "round"
                  ctx.stroke()

                  // Outer halo ring on physical button
                  ctx.beginPath()
                  ctx.arc(m.cx * sx, m.cy * sy, isHov ? 8.0 : 5.5, 0, Math.PI * 2)
                  ctx.fillStyle = light ? "#ffffff" : m.color
                  ctx.globalAlpha = isHov ? (light ? 0.85 : 0.42) : (light ? 0.70 : 0.24)
                  ctx.fill()

                  // Inner solid pin on physical button
                  ctx.beginPath()
                  ctx.arc(m.cx * sx, m.cy * sy, isHov ? 5.2 : 3.8, 0, Math.PI * 2)
                  ctx.fillStyle = m.color
                  ctx.globalAlpha = 1.0
                  ctx.fill()
                  ctx.restore()
                }
              }
            }

            // Clickable Pins directly on the Controller Graphic
            Repeater {
              model: root.buttonMetaList

              Item {
                id: pinHitbox
                required property var modelData
                x: modelData.cx * diagramContainer.sx - Style.space(11)
                y: modelData.cy * diagramContainer.sy - Style.space(11)
                width: Style.space(22)
                height: Style.space(22)

                MouseArea {
                  id: pinMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.hoveredButtonKey = pinHitbox.modelData.key
                  onExited: if (root.hoveredButtonKey === pinHitbox.modelData.key) root.hoveredButtonKey = ""
                  onClicked: root.openRebindModal(pinHitbox.modelData)
                }

                PanelToolTip {
                  visible: pinMouse.containsMouse
                  text: root.tooltipForButton(pinHitbox.modelData)
                  fontFamily: root.fontFamily
                }
              }
            }

            // 16 Interactive Callout Cards (8 Left + 8 Right)
            Repeater {
              model: root.buttonMetaList

              Item {
                id: calloutItem
                required property var modelData
                readonly property real cardW: 272 * diagramContainer.sx
                readonly property real cardH: 46 * diagramContainer.sy
                x: modelData.side === "left"
                  ? (modelData.tx - 272) * diagramContainer.sx
                  : modelData.tx * diagramContainer.sx
                y: (modelData.ty - 23) * diagramContainer.sy
                width: cardW
                height: cardH

                readonly property string rawAct: root.rawActionForButton(modelData.key)
                readonly property string actLabel: root.prettyAction(rawAct, 20)
                readonly property string descStr: root.descForButton(modelData.key)
                readonly property bool isHovered: root.hoveredButtonKey === modelData.key
                readonly property color badgeColor: Qt.color(modelData.color)

                BorderSurface {
                  anchors.fill: parent
                  radius: Style.space(6)
                  color: calloutItem.isHovered
                    ? root.alpha(calloutItem.badgeColor, root.isLightTheme ? 0.14 : 0.18)
                    : root.cardFillColor
                  borderSpec: Border.flat(
                    calloutItem.isHovered
                      ? calloutItem.badgeColor
                      : root.cardBorderColor,
                    calloutItem.isHovered ? 1.8 : 1.1
                  )

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(5)
                    anchors.rightMargin: Style.space(6)
                    spacing: Style.space(7)

                    // Colored Button Badge Pill
                    BorderSurface {
                      width: Style.space(54)
                      height: parent.height - Style.space(8)
                      anchors.verticalCenter: parent.verticalCenter
                      radius: Style.space(4)
                      color: root.alpha(calloutItem.badgeColor, root.isLightTheme ? 0.14 : 0.20)
                      borderSpec: Border.flat(calloutItem.badgeColor, 1.2)

                      Text {
                        anchors.centerIn: parent
                        text: calloutItem.modelData.label
                        color: calloutItem.badgeColor
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }
                    }

                    // Action + Inline Description Column
                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width - Style.space(67)
                      spacing: 0

                      Text {
                        width: parent.width
                        text: calloutItem.actLabel
                        color: calloutItem.rawAct === "None" ? root.dim : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        elide: Text.ElideRight
                      }

                      Text {
                        visible: calloutItem.descStr !== ""
                        width: parent.width
                        text: calloutItem.descStr
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Math.max(9, Style.font.caption - 2)
                        elide: Text.ElideRight
                      }
                    }
                  }
                }

                MouseArea {
                  id: cardMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.hoveredButtonKey = calloutItem.modelData.key
                  onExited: if (root.hoveredButtonKey === calloutItem.modelData.key) root.hoveredButtonKey = ""
                  onClicked: root.openRebindModal(calloutItem.modelData)
                }

                PanelToolTip {
                  visible: cardMouse.containsMouse
                  text: root.tooltipForButton(calloutItem.modelData)
                  fontFamily: root.fontFamily
                }
              }
            }
          }

          // ---------- Interactive Combos & Chords Footer Bar ----------
          BorderSurface {
            width: parent.width
            implicitHeight: combosCol.implicitHeight + Style.space(22)
            radius: Style.cornerRadius
            color: root.alpha(root.foreground, root.isLightTheme ? 0.045 : 0.04)
            borderSpec: Border.flat(root.cardBorderColor, 1.2)

            Column {
              id: combosCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(11)
              spacing: Style.space(8)

              Row {
                width: parent.width
                spacing: Style.space(8)

                BorderSurface {
                  width: Style.space(88)
                  height: Style.space(24)
                  radius: Style.space(4)
                  color: root.alpha(Qt.color(root.colShoulder), root.isLightTheme ? 0.14 : 0.18)
                  borderSpec: Border.flat(Qt.color(root.colShoulder), 1.2)

                  Text {
                    anchors.centerIn: parent
                    text: "⚡ COMBOS"
                    color: Qt.color(root.colShoulder)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.viewMode === "omarchy"
                    ? "Global Omarchy L2 Chords (inherited by all profiles · click any chip to edit)"
                    : ("Multi-button chords for [" + root.selectedProfileName.toUpperCase() + "] (click any chip to edit)")
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              Flow {
                width: parent.width
                spacing: Style.space(8)

                Repeater {
                  model: root.displayedCombos

                  BorderSurface {
                    id: comboChip
                    required property var modelData
                    implicitWidth: chipRow.implicitWidth + Style.space(18)
                    implicitHeight: Style.space(30)
                    radius: Style.space(6)
                    color: chipMouse.containsMouse
                      ? root.alpha(root.accent, root.isLightTheme ? 0.15 : 0.18)
                      : root.cardFillColor
                    borderSpec: Border.flat(
                      chipMouse.containsMouse ? root.accent : root.cardBorderColor,
                      chipMouse.containsMouse ? 1.5 : 1.1
                    )

                    Row {
                      id: chipRow
                      anchors.centerIn: parent
                      spacing: Style.space(6)

                      Text {
                        text: String(comboChip.modelData.combo || "")
                        color: Qt.color(root.colFace)
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }

                      Text {
                        text: "➔"
                        color: root.accent
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }

                      Text {
                        text: root.prettyAction(comboChip.modelData.label, 18)
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }

                      Text {
                        visible: String(comboChip.modelData.description || "") !== ""
                        text: "• " + String(comboChip.modelData.description || "")
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                    }

                    MouseArea {
                      id: chipMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.openComboRebindModal(comboChip.modelData)
                    }

                    PanelToolTip {
                      visible: chipMouse.containsMouse
                      text: String(comboChip.modelData.combo) + "  ➔  " + String(comboChip.modelData.label)
                        + (comboChip.modelData.description ? ("\n“" + comboChip.modelData.description + "”") : "")
                        + "\n(Click to edit combo binding)"
                      fontFamily: root.fontFamily
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // ---------- Interactive Rebind Modal Overlay ----------
    Rectangle {
      visible: root.editingBinding
      anchors.fill: parent
      radius: Style.cornerRadius
      color: Qt.rgba(0, 0, 0, root.isLightTheme ? 0.45 : 0.68)
      z: 50

      MouseArea {
        anchors.fill: parent
        onClicked: {
          root.cancelPhysicalKeyCapture()
          root.editingBinding = false
        }
      }

      BorderSurface {
        width: Math.min(parent.width - Style.space(48), Style.space(560))
        implicitHeight: modalCol.implicitHeight + Style.space(36)
        anchors.centerIn: parent
        radius: Style.cornerRadius
        color: root.surface
        borderSpec: Border.flat(Qt.color(root.editButtonColor), 1.8)

        MouseArea {
          anchors.fill: parent
          onClicked: {}
        }

        Column {
          id: modalCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.space(18)
          spacing: Style.space(12)

          // Modal Title
          Row {
            width: parent.width
            spacing: Style.space(10)

            BorderSurface {
              width: Style.space(14)
              height: Style.space(26)
              radius: Style.space(4)
              color: Qt.color(root.editButtonColor)
            }

            Column {
              spacing: Style.space(2)

              Text {
                text: "Change Keybinding · " + root.editButtonLabel
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }

              Text {
                text: "Capture a physical keypress, click a preset chip, or enter a custom key / exec: command."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          // Live Physical Keyboard Capture Button
          Button {
            width: parent.width
            text: root.capturingKeypress
              ? "🎙️ Listening for physical keyboard press… (Press ESC on keyboard to cancel)"
              : "🎙️ Press to Capture Key / Chord Directly from Your Keyboard"
            selected: root.capturingKeypress
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            verticalPadding: Style.space(9)
            onClicked: {
              if (root.capturingKeypress) root.cancelPhysicalKeyCapture()
              else root.startPhysicalKeyCapture()
            }
          }

          // Key / Chord / Exec Input Field
          Column {
            width: parent.width
            spacing: Style.space(4)

            Text {
              text: "KEY / CHORD OR SHELL COMMAND (e.g. K, LEFTCTRL+T, VolumeUp, exec:...)"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            TextField {
              id: keyInput
              width: parent.width
              text: root.editKeyText
              placeholderText: "e.g. Space, LEFTALT+LEFT, F9, or exec:omarchy-launch-terminal"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              padding: Style.space(8)
              onTextChanged: root.editKeyText = text
              Keys.onReturnPressed: root.saveEditedBinding(false)
              Keys.onEscapePressed: {
                root.cancelPhysicalKeyCapture()
                root.editingBinding = false
              }
              background: Rectangle {
                radius: Style.space(6)
                color: root.cardFillColor
                border.color: keyInput.activeFocus ? root.accent : root.cardBorderColor
                border.width: keyInput.activeFocus ? 1.5 : 1
              }
            }
          }

          // Tooltip / Description Input Field
          Column {
            width: parent.width
            spacing: Style.space(4)

            Text {
              text: "TOOLTIP / SUBTITLE DESCRIPTION (saved as inline # comment in profiles.toml)"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            TextField {
              id: descInput
              width: parent.width
              text: root.editDescText
              placeholderText: "e.g. Play / Pause video, Focus search bar, Toggle fullscreen"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              padding: Style.space(8)
              onTextChanged: root.editDescText = text
              Keys.onReturnPressed: root.saveEditedBinding(false)
              Keys.onEscapePressed: {
                root.cancelPhysicalKeyCapture()
                root.editingBinding = false
              }
              background: Rectangle {
                radius: Style.space(6)
                color: root.cardFillColor
                border.color: descInput.activeFocus ? root.accent : root.cardBorderColor
                border.width: descInput.activeFocus ? 1.5 : 1
              }
            }
          }

          // Quick-Pick Key Chips
          Column {
            width: parent.width
            spacing: Style.space(6)

            Text {
              text: "QUICK-PICK KEYS"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.quickKeyChips

                Button {
                  required property var modelData
                  text: modelData.label
                  selected: root.editKeyText === modelData.value
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  verticalPadding: Style.space(4)
                  horizontalPadding: Style.space(8)
                  onClicked: root.editKeyText = modelData.value
                }
              }
            }
          }

          // Modal Action Buttons
          Row {
            width: parent.width
            spacing: Style.space(10)
            readonly property real actW: (width - spacing * 2) / 3

            Button {
              width: parent.actW
              text: "✓ Save & Reload"
              selected: true
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(8)
              onClicked: root.saveEditedBinding(false)
            }

            Button {
              width: parent.actW
              text: "⊘ Clear (None)"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(8)
              onClicked: root.saveEditedBinding(true)
            }

            Button {
              width: parent.actW
              text: "✕ Cancel"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(8)
              onClicked: {
                root.cancelPhysicalKeyCapture()
                root.editingBinding = false
              }
            }
          }
        }
      }
    }
  }
}
