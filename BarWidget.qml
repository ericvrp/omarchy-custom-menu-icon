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
  property string panelSelection: "default"
  property string builtInMenuIcon: "\ue900"
  property string imagePath: ""
  property string imageError: ""
  property int imageRequestSerial: 0

  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  readonly property string configuredValue: String(root.setting("text", ""))
  readonly property bool isImageUrl: /^https:\/\//i.test(root.configuredValue)
  readonly property string displayText: root.configuredValue && !root.isImageUrl
    ? root.configuredValue
    : root.builtInMenuIcon
  readonly property bool showingImage: root.isImageUrl && root.imagePath !== ""
  readonly property bool customOpen: root.panelSelection === "custom"
  readonly property string fetchScript: decodeURIComponent(
    Qt.resolvedUrl("scripts/fetch-image.sh").toString().replace(/^file:\/\//, "")
  )
  readonly property var presetOptions: [
    { id: "default", label: "Omarchy", value: "", kind: "builtin" },
    { id: "heart", label: "Heart", value: "❤️", kind: "text" },
    {
      id: "rainbow-apple",
      label: "Rainbow Apple",
      value: "https://commons.wikimedia.org/wiki/Special:FilePath/Apple%20Computer%20Logo%20rainbow.svg",
      kind: "image"
    },
    {
      id: "modern-apple",
      label: "Modern Apple",
      value: "https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_black.svg",
      kind: "image"
    },
    {
      id: "white-apple",
      label: "White Apple",
      value: "https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_white.svg",
      kind: "image"
    },
    {
      id: "windows",
      label: "Windows",
      value: "https://commons.wikimedia.org/wiki/Special:FilePath/Windows_logo_-_2012.svg",
      kind: "image"
    },
    { id: "custom", label: "Custom", value: "", kind: "custom" }
  ]
  readonly property bool opened: root.editorOpen

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function focusEditor() {
    if (!root.editorOpen || !root.customOpen) return
    editorField.forceActiveFocus()
    editorField.selectAll()
  }

  function presetForValue(value) {
    var candidate = String(value === undefined || value === null ? "" : value)
    for (var i = 0; i < root.presetOptions.length; i++) {
      var option = root.presetOptions[i]
      if (option.kind !== "custom" && String(option.value) === candidate) return option.id
    }
    return "custom"
  }

  function showCustomEditor() {
    root.panelSelection = "custom"
    editorField.text = root.configuredValue
    Qt.callLater(root.focusEditor)
  }

  function choosePreset(option) {
    if (!option) return
    if (option.id === "custom") {
      root.showCustomEditor()
      return
    }
    root.saveValue(option.value)
  }

  function openEditor() {
    if (root.editorOpen) {
      return
    }
    root.panelSelection = root.presetForValue(root.configuredValue)
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

  // Read the stock widget rather than a screenshot or copied PNG. This keeps
  // the preset aligned with the current Omarchy menu glyph if Omarchy changes
  // it in a future release.
  function loadBuiltInMenuIcon(source) {
    var match = String(source || "").match(/text\s*:\s*"((?:\\.|[^"])*)"/)
    if (!match) return
    try {
      var icon = JSON.parse('"' + match[1] + '"')
      if (icon) root.builtInMenuIcon = icon
    } catch (error) {
      // Keep the known stock fallback when the packaged source is unavailable
      // or its syntax is not a simple quoted text binding.
    }
  }

  FileView {
    id: stockMenuBarWidgetFile
    path: root.omarchyPath + "/shell/plugins/menu/BarWidget.qml"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadBuiltInMenuIcon(text())
    onFileChanged: reload()
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

  function scheduleImageRefresh() {
    if (root.componentReady) imageRefreshTimer.restart()
  }

  Timer {
    id: imageRefreshTimer
    interval: 20
    onTriggered: root.refreshImage()
  }

  // Depending on whether a value came from the CLI or the editor, QML may
  // invalidate either the settings object or the derived value first. Debounce
  // both notifications into one image request.
  onSettingsChanged: root.scheduleImageRefresh()
  onConfiguredValueChanged: root.scheduleImageRefresh()
  Component.onCompleted: {
    root.componentReady = true
    root.scheduleImageRefresh()
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
    fontFamily: root.displayText === root.builtInMenuIcon
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
        root.toggleEditor()
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
    focusTarget: root.customOpen ? editorField : null
    contentWidth: editorPopup.fittedContentWidth(Style.space(390))
    contentHeight: editorPopup.fittedContentHeight(editorColumn.implicitHeight)

    onOpenChanged: if (open && root.customOpen) Qt.callLater(root.focusEditor)

    Column {
      id: editorColumn

      width: parent.width
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: "Choose menu icon"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: "Choose a preset, or select Custom to enter your own text, emoji, or HTTPS image URL."
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        opacity: 0.72
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Grid {
        id: presetGrid

        width: parent.width
        columns: 3
        spacing: Style.space(6)
        property real cellHeight: Style.space(78)
        property int rowCount: Math.ceil(root.presetOptions.length / columns)
        height: rowCount * cellHeight + Math.max(0, rowCount - 1) * spacing

        Repeater {
          model: root.presetOptions

          delegate: Button {
            required property var modelData

            width: (presetGrid.width - presetGrid.spacing * (presetGrid.columns - 1)) / presetGrid.columns
            height: presetGrid.cellHeight
            text: ""
            iconText: ""
            horizontalPadding: 0
            verticalPadding: 0
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true
            selected: root.panelSelection === modelData.id
            onClicked: root.choosePreset(modelData)

            Column {
              enabled: false
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(2)

              Item {
                width: parent.width
                height: Style.space(38)

                Rectangle {
                  visible: modelData.kind === "image"
                  anchors.centerIn: parent
                  width: Style.space(38)
                  height: width
                  radius: Style.cornerRadius
                  color: modelData.id === "modern-apple"
                    ? (root.bar ? root.bar.foreground : Color.foreground)
                    : (modelData.id === "white-apple"
                      ? (root.bar ? root.bar.background : Color.background)
                      : "transparent")
                }

                Text {
                  visible: modelData.kind === "builtin"
                    || modelData.kind === "text"
                    || modelData.kind === "custom"
                  anchors.centerIn: parent
                  text: modelData.kind === "builtin"
                    ? root.builtInMenuIcon
                    : (modelData.kind === "custom" ? "Aa" : modelData.value)
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: modelData.kind === "builtin"
                    ? "omarchy"
                    : (root.bar ? root.bar.fontFamily : Style.font.family)
                  font.pixelSize: modelData.kind === "builtin"
                    ? Style.font.display
                    : (modelData.kind === "custom" ? Style.font.title : Style.font.display)
                }

                Image {
                  visible: modelData.kind === "image"
                  anchors.centerIn: parent
                  width: Style.space(34)
                  height: width
                  asynchronous: true
                  cache: true
                  mipmap: true
                  smooth: true
                  fillMode: Image.PreserveAspectFit
                  sourceSize.width: width
                  sourceSize.height: height
                  source: modelData.kind === "image" ? modelData.value : ""
                }
              }

              Text {
                width: parent.width
                height: implicitHeight
                textFormat: Text.PlainText
                text: modelData.label
                color: root.bar ? root.bar.foreground : Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      Item {
        id: customFormContainer
        width: parent.width
        visible: root.customOpen
        height: visible ? customForm.implicitHeight : 0
        implicitHeight: height

        Column {
          id: customForm
          width: parent.width
          spacing: Style.space(8)

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
              text: "Cancel"
              foreground: root.bar ? root.bar.foreground : Color.foreground
              onClicked: root.closeEditor()
            }
          }
        }
      }
    }
  }
}
