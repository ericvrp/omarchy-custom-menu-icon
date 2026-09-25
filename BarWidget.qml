import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// A fork of omarchy.menu's bar widget. The menu implementation remains the
// stock menu so existing Omarchy commands and menu extensions continue to
// work, while the button itself can display text, emoji, or a cached image.
BarWidget {
  id: root

  // Keep the built-in target in source code. The manifest's clonedFrom entry
  // makes the shell route omarchy.menu IPC to this plugin.
  moduleName: "omarchy.menu"

  property bool editorOpen: false
  property bool componentReady: false
  property string imagePath: ""
  property string imageError: ""
  property int imageRequestSerial: 0

  readonly property string configuredValue: String(root.setting("text", ""))
  readonly property bool isImageUrl: /^https:\/\//i.test(root.configuredValue)
  readonly property string displayText: root.configuredValue && !root.isImageUrl
    ? root.configuredValue
    : "\ue900"
  readonly property bool showingImage: root.isImageUrl && root.imagePath !== ""
  readonly property string fetchScript: decodeURIComponent(
    Qt.resolvedUrl("scripts/fetch-image.sh").toString().replace(/^file:\/\//, "")
  )
  readonly property bool opened: root.editorOpen

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function focusEditor() {
    if (!root.editorOpen) return
    editorField.forceActiveFocus()
    editorField.selectAll()
  }

  function openEditor() {
    if (root.editorOpen) {
      root.focusEditor()
      return
    }
    editorField.text = root.configuredValue
    // KeyboardPanel is a full-screen layer surface. Mapping it during the
    // initiating mouse-release event lets its dismissal surface consume that
    // same click and close it immediately. Wait until the event is complete.
    editorOpenTimer.restart()
  }

  function closeEditor() {
    editorOpenTimer.stop()
    root.editorOpen = false
  }

  // KeyboardPanel calls the owner using the standard popup lifecycle names.
  function open() { root.openEditor() }
  function close() { root.closeEditor() }

  function toggleEditor() {
    if (root.editorOpen) root.closeEditor()
    else root.openEditor()
  }

  Timer {
    id: editorOpenTimer
    interval: 100
    onTriggered: {
      root.editorOpen = true
      Qt.callLater(root.focusEditor)
    }
  }

  function saveValue(value) {
    var nextValue = String(value === undefined || value === null ? "" : value).trim()
    var nextSettings = { id: root.moduleName }
    var currentSettings = root.settings || ({})

    for (var key in currentSettings) {
      if (key !== "id" && key !== "text") nextSettings[key] = currentSettings[key]
    }
    if (nextValue !== "") nextSettings.text = nextValue

    // Update this instance immediately, then let the shell persist and fan the
    // setting out to the other bar surfaces/monitors.
    root.settings = nextSettings
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, nextSettings)

    root.closeEditor()
  }

  function refreshImage() {
    root.imageRequestSerial++
    root.imagePath = ""
    root.imageError = ""

    if (!root.componentReady || !root.isImageUrl) {
      if (imageProcess.running) imageProcess.running = false
      return
    }

    if (imageProcess.running) imageProcess.running = false
    imageProcess.requestSerial = root.imageRequestSerial
    imageProcess.command = [root.fetchScript, root.configuredValue]
    imageProcess.running = true
  }

  onConfiguredValueChanged: if (root.componentReady) root.refreshImage()
  Component.onCompleted: {
    root.componentReady = true
    root.refreshImage()
  }

  Process {
    id: imageProcess

    property int requestSerial: 0

    stdout: StdioCollector {
      onStreamFinished: {
        if (imageProcess.requestSerial !== root.imageRequestSerial) return
        var lines = String(text || "").trim().split("\n")
        var path = lines.length > 0 ? lines[lines.length - 1].trim() : ""
        if (path !== "") root.imagePath = path
      }
    }

    onExited: function(exitCode) {
      if (imageProcess.requestSerial !== root.imageRequestSerial) return
      if (exitCode !== 0) root.imageError = "The image could not be downloaded"
    }
  }

  WidgetButton {
    id: button

    anchors.fill: parent
    bar: root.bar
    text: root.showingImage ? "\u200b" : root.displayText
    fontFamily: root.displayText === "\ue900"
      ? "omarchy"
      : root.setting("fontFamily", root.bar ? root.bar.fontFamily : Style.font.family)
    fixedWidth: root.showingImage ? root.barSize : -1
    labelVisible: !root.showingImage
    hasVisualContent: true
    keepSpace: true
    horizontalMargin: root.showingImage ? 4 : 7.5
    tooltipText: root.isImageUrl
      ? (root.showingImage ? root.configuredValue : "Downloading menu image…")
      : "Right-click to customize"

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        root.openEditor()
      } else if (mouseButton === Qt.MiddleButton) {
        root.closeEditor()
        if (root.bar) root.bar.run("xdg-terminal-exec")
      } else {
        root.closeEditor()
        if (root.bar) root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
      }
    }

    Image {
      anchors.centerIn: parent
      visible: root.showingImage
      enabled: false
      asynchronous: true
      mipmap: true
      smooth: true
      width: Math.max(16, root.barSize - 8)
      height: Math.max(16, root.barSize - 8)
      fillMode: Image.PreserveAspectFit
      sourceSize.width: width
      sourceSize.height: height
      source: root.showingImage ? Util.fileUrl(root.imagePath) : ""
    }
  }

  KeyboardPanel {
    id: editorPopup

    anchorItem: button
    bar: root.bar
    owner: root
    open: root.editorOpen
    focusTarget: editorField
    contentWidth: editorPopup.fittedContentWidth(Style.space(390))
    contentHeight: editorPopup.fittedContentHeight(editorColumn.implicitHeight)

    onOpenChanged: if (open) Qt.callLater(root.focusEditor)

    Column {
      id: editorColumn

      width: parent.width
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: "Omarchy menu icon"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      TextField {
        id: editorField

        width: parent.width
        placeholderText: "Text, emoji, or https://… image URL"
        foreground: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        onAccepted: root.saveValue(text)
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.closeEditor()
            event.accepted = true
          }
        }
      }

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: "Keep this field focused, then use the normal Omarchy emoji picker (Super+Ctrl+E) to paste an emoji here."
        color: root.bar ? root.bar.foreground : Color.foreground
        opacity: 0.72
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Row {
        spacing: Style.space(6)

        Button {
          text: "Save"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.saveValue(editorField.text)
        }

        Button {
          text: "Reset"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.saveValue("")
        }

        Button {
          text: "Cancel"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.closeEditor()
        }
      }
    }
  }
}
