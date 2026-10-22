import QtQuick
import qs.Commons

// SafeTextInput: A read-only native TextInput with bounded key handling.
// Prevents QtDeclarative from eagerly reading the system clipboard on dataChanged
// without a user paste action (mitigating shell memory exhaustion / hang risks in Quickshell).
FocusScope {
  id: root
  property alias text: input.text
  property string placeholderText: ""
  property color foreground: "white"
  property color accent: foreground
  property color cardFillColor: "transparent"
  property color cardBorderColor: "gray"
  property alias font: input.font
  property int maximumLength: 256

  signal returnPressed()
  signal escapePressed()

  function forceActiveFocus() { input.forceActiveFocus() }
  function selectAll() { input.selectAll() }

  implicitWidth: 200
  implicitHeight: Style.space(36)

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Style.space(6)
    color: root.cardFillColor
    border.color: input.activeFocus ? root.accent : root.cardBorderColor
    border.width: input.activeFocus ? 1.5 : 1

    Text {
      anchors.fill: parent
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      text: root.placeholderText
      textFormat: Text.PlainText
      font: input.font
      color: root.foreground
      opacity: 0.45
      visible: input.text.length === 0
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }

    TextInput {
      id: input
      anchors.fill: parent
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      focus: true
      readOnly: true
      maximumLength: root.maximumLength
      activeFocusOnTab: true
      selectByMouse: true
      cursorVisible: activeFocus
      clip: true
      color: root.foreground
      selectionColor: root.accent
      selectedTextColor: "black"
      verticalAlignment: TextInput.AlignVCenter
      Accessible.name: root.placeholderText

      function replaceSelection(replacement) {
        var start = selectionStart
        var end = selectionEnd
        var room = root.maximumLength - (text.length - (end - start))
        var bounded = replacement.slice(0, room)
        var last = bounded.charCodeAt(bounded.length - 1)
        if (last >= 0xd800 && last <= 0xdbff) bounded = bounded.slice(0, -1)
        text = text.slice(0, start) + bounded + text.slice(end)
        cursorPosition = start + bounded.length
      }

      function handleKey(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.returnPressed()
          event.accepted = true
          return true
        }
        if (event.key === Qt.Key_Escape) {
          root.escapePressed()
          event.accepted = true
          return true
        }

        var shortcut = event.modifiers & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier)
        if (shortcut) {
          if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            selectAll()
            event.accepted = true
            return true
          }
          return false
        }

        if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
          if (selectionStart === selectionEnd) {
            var position = cursorPosition
            if (event.key === Qt.Key_Backspace && position > 0) {
              var previous = text.charCodeAt(position - 1)
              var count = previous >= 0xdc00 && previous <= 0xdfff && position > 1 ? 2 : 1
              select(position - count, position)
            } else if (event.key === Qt.Key_Delete && position < text.length) {
              var next = text.charCodeAt(position)
              var count = next >= 0xd800 && next <= 0xdbff && position + 1 < text.length ? 2 : 1
              select(position, position + count)
            }
          }
          replaceSelection("")
        } else if (event.text && !/[\x00-\x1f\x7f]/.test(event.text)) {
          replaceSelection(event.text)
        } else {
          return false
        }
        event.accepted = true
        return true
      }

      Keys.onPressed: function(event) { handleKey(event) }
    }
  }
}
