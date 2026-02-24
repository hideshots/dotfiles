import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtCore
import Qt5Compat.GraphicalEffects

import "." as Root
import "menu" as Menu
import "modules/notifications" as Notifications
import "widgets" as Widgets

ShellRoot {
  id: shell
  // Force-load notifications backend so NotificationServer is active without UI components.
  readonly property var notificationService: Root.NotificationService
  Component.onCompleted: notificationService.refreshTimeLabels()
  // Notifications { }
  property bool weatherEnabled: true
  property bool calendarEnabled: true
  property bool notificationsPopupEnabled: true
  property int notificationsPopupTopMargin: 44
  property int notificationsPopupRightMargin: 16
  property int notificationsPopupMaxVisible: 5
  property bool notificationCenterOpen: false
  property var notificationCenterTriggerItem: null
  property bool notificationCenterEnabled: true
  property int notificationCenterTopMargin: 44
  property int notificationCenterRightMargin: 16
  onNotificationCenterOpenChanged: {
    if (!shell.notificationCenterOpen) {
      shell.notificationCenterTriggerItem = null
    }
  }
  function toggleNotificationCenter(triggerItem) {
    var hasTrigger = triggerItem !== undefined && triggerItem !== null

    if (shell.notificationCenterOpen) {
      if (hasTrigger && shell.notificationCenterTriggerItem !== triggerItem) {
        shell.notificationCenterTriggerItem = triggerItem
        return
      }
      shell.notificationCenterOpen = false
      return
    }

    shell.notificationCenterTriggerItem = hasTrigger ? triggerItem : null
    shell.notificationCenterOpen = true
  }
  Shortcut {
    sequence: "Escape"
    context: Qt.ApplicationShortcut
    enabled: shell.notificationCenterOpen
    onActivated: shell.notificationCenterOpen = false
  }
  property int weatherPanelTopMargin: 50
  property int weatherPanelLeftMargin: 10
  property int calendarPanelGap: 10
  property string weatherLocation: "Krasnodar"
  property string weatherDisplayLocation: "Richmond"
  property string weatherUnits: "u"
  property string weatherVariant: "medium"
  property bool widgetGlassDebug: false
  property real widgetGlassRefraction: 8.2
  property real widgetGlassBodyRefractionWidthPx: 32.0
  property real widgetGlassDepth: 0.2
  property real widgetGlassDispersion: 1.0
  property real widgetGlassFrost: 0.7
  property real widgetGlassSplay: 2.5
  property real widgetGlassSplayDepth: 30.0
  property real widgetGlassRimWidth: 15.0
  property real widgetGlassRimStrength: 1.0
  property real widgetGlassBodyDepth: 64.0
  property real widgetGlassBodyExponent: 0.75
  property real widgetGlassBodyStrength: 0.25
  property real widgetGlassMagnifyStrength: -0.1
  property real widgetGlassVibrance: 0.8
  property int widgetGlassDebugView: 0
  property real widgetGlassLightAngleDeg: 335
  property real widgetGlassLightStrength: 3.0
  property real widgetGlassLightWidthPx: 3.0
  property real widgetGlassLightSharpness: 0.0
  property real widgetGlassCornerBoost: 0.5
  property real widgetGlassDispersionLimit: 1.0
  property real widgetGlassDispersionWidthPx: 9.0
  property real widgetGlassDispersionCurve: 0.9
  property real widgetGlassOpacity: 1.0
  property color widgetGlassTint: Qt.rgba(1.0, 1.0, 1.0, 0.08)
  property real widgetGlassBlurSize: 0.7
  property real widgetGlassBlurPasses: 2
  property bool widgetGlassLiveCapture: false
  property bool widgetGlassAutoRecapture: false
  readonly property string _cacheDir: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
  readonly property string _wallpaperStatePath: shell._cacheDir + "/quickshell/wallpaper"
  property string _wallpaperPathRaw: ""
  property string _wallpaperProbeLoadedPath: ""
  readonly property string wallpaperPathTrimmed: String(shell._wallpaperPathRaw).trim()
  readonly property bool wallpaperFileExists: shell.wallpaperPathTrimmed.length > 0 && shell._wallpaperProbeLoadedPath === shell.wallpaperPathTrimmed
  readonly property bool useWallpaperSource: shell.wallpaperPathTrimmed.length > 0 && shell.wallpaperFileExists
  readonly property string widgetWallpaperSource: shell.useWallpaperSource ? shell.wallpaperPathTrimmed : ""

  onWallpaperPathTrimmedChanged: shell._wallpaperProbeLoadedPath = ""

  FileView {
    id: wallpaperStateFile
    path: shell._wallpaperStatePath
    preload: true
    watchChanges: true
    printErrors: false
    onLoaded: shell._wallpaperPathRaw = wallpaperStateFile.text()
    onLoadFailed: shell._wallpaperPathRaw = ""
    onFileChanged: wallpaperStateFile.reload()
  }

  FileView {
    id: wallpaperProbeFile
    path: shell.wallpaperPathTrimmed.length > 0 ? shell.wallpaperPathTrimmed : ""
    preload: true
    watchChanges: true
    printErrors: false
    onLoaded: shell._wallpaperProbeLoadedPath = wallpaperProbeFile.path
    onLoadFailed: shell._wallpaperProbeLoadedPath = ""
    onFileChanged: wallpaperProbeFile.reload()
  }

  PanelWindow {
    id: weatherPanel
    visible: shell.weatherEnabled

    anchors.top: true
    anchors.left: true
    margins.top: shell.weatherPanelTopMargin
    margins.left: shell.weatherPanelLeftMargin + (shell.calendarEnabled ? (calendarWidget.implicitWidth + shell.calendarPanelGap) : 0)
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    surfaceFormat.opaque: false
    focusable: false
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:weather"
    HyprlandWindow.visibleMask: weatherMask

    implicitWidth: weatherWidget.implicitWidth
    implicitHeight: weatherWidget.implicitHeight

    Region {
      id: weatherMask
      item: weatherWidget
    }

    Widgets.WeatherWidget {
      id: weatherWidget
      anchors.fill: parent
      screen: weatherPanel.screen
      location: shell.weatherLocation
      displayLocation: shell.weatherDisplayLocation
      units: shell.weatherUnits
      variant: shell.weatherVariant
      wallpaperSource: shell.widgetWallpaperSource
      refraction: shell.widgetGlassRefraction
      depth: shell.widgetGlassDepth
      dispersion: shell.widgetGlassDispersion
      frost: shell.widgetGlassFrost
      splay: shell.widgetGlassSplay
      splayDepth: shell.widgetGlassSplayDepth
      rimWidth: shell.widgetGlassRimWidth
      rimStrength: shell.widgetGlassRimStrength
      bodyDepth: shell.widgetGlassBodyDepth
      bodyExponent: shell.widgetGlassBodyExponent
      bodyStrength: shell.widgetGlassBodyStrength
      magnifyStrength: shell.widgetGlassMagnifyStrength
      vibrance: shell.widgetGlassVibrance
      lightAngleDeg: shell.widgetGlassLightAngleDeg
      lightStrength: shell.widgetGlassLightStrength
      lightWidthPx: shell.widgetGlassLightWidthPx
      lightSharpness: shell.widgetGlassLightSharpness
      bodyRefractionWidthPx: shell.widgetGlassBodyRefractionWidthPx
      cornerBoost: shell.widgetGlassCornerBoost
      dispersionLimit: shell.widgetGlassDispersionLimit
      dispersionWidthPx: shell.widgetGlassDispersionWidthPx
      dispersionCurve: shell.widgetGlassDispersionCurve
      glassOpacity: shell.widgetGlassOpacity
      glassTint: shell.widgetGlassTint
      blurSize: shell.widgetGlassBlurSize
      blurPasses: shell.widgetGlassBlurPasses
      liveCapture: shell.widgetGlassLiveCapture
      autoRecapture: shell.widgetGlassAutoRecapture
      glassDebug: shell.widgetGlassDebug
      glassDebugView: shell.widgetGlassDebugView
      onRequestContextMenu: function(x, y) {
        weatherSizeMenu.anchorPointX = x + 4;
        weatherSizeMenu.anchorPointY = y + 8;
        weatherSizeMenu.anchor.updateAnchor();
        if (weatherSizeMenu.visible) {
          weatherSizeMenu.close();
        }
        weatherSizeMenu.open();
      }
    }

    Menu.MenuPopup {
      id: weatherSizeMenu
      anchorItem: weatherWidget
      yOffset: 8
      adaptiveWidth: true
      model: [
        {
          type: "action",
          label: "Small",
          reserveCheckmark: true,
          checked: shell.weatherVariant === "small",
          action: function() { shell.weatherVariant = "small"; }
        },
        {
          type: "action",
          label: "Medium",
          reserveCheckmark: true,
          checked: shell.weatherVariant === "medium",
          action: function() { shell.weatherVariant = "medium"; }
        }
      ]
    }
  }

  PanelWindow {
    id: calendarPanel
    visible: shell.weatherEnabled && shell.calendarEnabled

    anchors.top: true
    anchors.left: true
    margins.top: shell.weatherPanelTopMargin
    margins.left: shell.weatherPanelLeftMargin
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    surfaceFormat.opaque: false
    focusable: false
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:calendar"
    HyprlandWindow.visibleMask: calendarMask

    implicitWidth: calendarWidget.implicitWidth
    implicitHeight: calendarWidget.implicitHeight

    Region {
      id: calendarMask
      item: calendarWidget
    }

    Widgets.CalendarWidget {
      id: calendarWidget
      anchors.fill: parent
      screen: calendarPanel.screen
      wallpaperSource: shell.widgetWallpaperSource
      refraction: shell.widgetGlassRefraction
      depth: shell.widgetGlassDepth
      dispersion: shell.widgetGlassDispersion
      frost: shell.widgetGlassFrost
      splay: shell.widgetGlassSplay
      splayDepth: shell.widgetGlassSplayDepth
      rimWidth: shell.widgetGlassRimWidth
      rimStrength: shell.widgetGlassRimStrength
      bodyDepth: shell.widgetGlassBodyDepth
      bodyExponent: shell.widgetGlassBodyExponent
      bodyStrength: shell.widgetGlassBodyStrength
      magnifyStrength: shell.widgetGlassMagnifyStrength
      vibrance: shell.widgetGlassVibrance
      lightAngleDeg: shell.widgetGlassLightAngleDeg
      lightStrength: shell.widgetGlassLightStrength
      lightWidthPx: shell.widgetGlassLightWidthPx
      lightSharpness: shell.widgetGlassLightSharpness
      bodyRefractionWidthPx: shell.widgetGlassBodyRefractionWidthPx
      cornerBoost: shell.widgetGlassCornerBoost
      dispersionLimit: shell.widgetGlassDispersionLimit
      dispersionWidthPx: shell.widgetGlassDispersionWidthPx
      dispersionCurve: shell.widgetGlassDispersionCurve
      glassOpacity: shell.widgetGlassOpacity
      glassTint: shell.widgetGlassTint
      blurSize: shell.widgetGlassBlurSize
      blurPasses: shell.widgetGlassBlurPasses
      liveCapture: shell.widgetGlassLiveCapture
      autoRecapture: shell.widgetGlassAutoRecapture
      glassDebug: shell.widgetGlassDebug
      glassDebugView: shell.widgetGlassDebugView
    }
  }

  PanelWindow {
    id: notificationsPopupPanel
    visible: shell.notificationsPopupEnabled && shell.notificationService.activeCount > 0

    anchors.top: true
    anchors.right: true
    margins.top: shell.notificationsPopupTopMargin
    margins.right: shell.notificationsPopupRightMargin
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    surfaceFormat.opaque: false
    focusable: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:notifications"

    implicitWidth: popupStack.implicitWidth
    implicitHeight: popupStack.implicitHeight

    Notifications.PopupStack {
      id: popupStack
      anchors.fill: parent
      maxVisible: shell.notificationsPopupMaxVisible
    }
  }

  PanelWindow {
    id: notificationCenterOverlayPanel
    visible: shell.notificationCenterEnabled && (shell.notificationCenterOpen || notificationCenter.opacity > 0.01)

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    surfaceFormat.opaque: false
    focusable: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:notification-center-overlay"

    MouseArea {
      id: notificationCenterBackdropMouseArea
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      preventStealing: true

      onPressed: function(mouse) {
        mouse.accepted = true;
      }

      onClicked: function(mouse) {
        mouse.accepted = true;

        var panelPos = notificationCenter.mapToItem(notificationCenterBackdropMouseArea, 0, 0);
        var insidePanel = mouse.x >= panelPos.x
          && mouse.x <= panelPos.x + notificationCenter.width
          && mouse.y >= panelPos.y
          && mouse.y <= panelPos.y + notificationCenter.height;

        if (!insidePanel) {
          shell.notificationCenterOpen = false;
        }
      }
    }

    Notifications.NotificationCenter {
      id: notificationCenter
      z: 1
      width: implicitWidth
      height: implicitHeight
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: shell.notificationCenterTopMargin
      anchors.rightMargin: shell.notificationCenterRightMargin
      open: shell.notificationCenterOpen
      onRequestClose: shell.notificationCenterOpen = false
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanelWindow
      WlrLayershell.namespace: "qsbar"
      required property var modelData
      screen: barPanelWindow.modelData
      property bool notificationCenterOpenProxy: shell.notificationCenterOpen
      property var notificationCenterTriggerItemProxy: shell.notificationCenterTriggerItem
      function toggleNotificationCenterForBar(triggerItem) {
        shell.toggleNotificationCenter(triggerItem)
      }

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 72
      color: "transparent"

      exclusiveZone: 36

      mask: Region { item: barHitbox }

      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 72
        color: "transparent"

        gradient: Gradient {
          GradientStop { position: 0.00; color: Theme.isDark ? Qt.rgba(0,0,0,0.18) : Qt.rgba(1,1,1,0.12) }
          GradientStop { position: 0.25; color: Theme.isDark ? Qt.rgba(0,0,0,0.10) : Qt.rgba(1,1,1,0.07) }
          GradientStop { position: 0.60; color: Theme.isDark ? Qt.rgba(0,0,0,0.04) : Qt.rgba(1,1,1,0.01) }
          GradientStop { position: 1.00; color: "transparent" }
        }
      }

      Item {
        id: barHitbox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36

        Rectangle {
          anchors.fill: parent
          color: Theme.background

          Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            spacing: 0

            Item {
              id: leftSection
              height: parent.height
              width: leftRow.implicitWidth

              QtObject {
                id: leftHi
                property Item activeTarget: null
                property Item pulseTarget: null
                property bool pressed: false
              }

              Rectangle {
                id: leftPill
                z: 0
                radius: Theme.borderRadius

                property Item target: leftHi.activeTarget ?? leftHi.pulseTarget

                x: target ? target.mapToItem(leftSection, 0, 0).x - Theme.hoverOverlap : 0
                y: 0
                width: target ? target.width + (Theme.hoverOverlap * 2) : 0
                height: parent.height

                color: leftHi.activeTarget
                ? Qt.rgba(1, 1, 1, 0.10)
                : (leftHi.pulseTarget
                ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.70)
                : "transparent")

                opacity: target ? 1 : 0
              }

              Row {
                id: leftRow
                z: 1
                spacing: 0
                height: parent.height

                // Apple logo (remove per-item hover bg; let leftPill handle it)
                Rectangle {
                  id: logoRect
                  width: 35
                  height: parent.height
                  color: "transparent"
                  radius: Theme.borderRadius

                  Text {
                    id: logoText
                    anchors.centerIn: parent
                    text: "􀆿"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.iconSize
                    renderType: Text.NativeRendering
                    color: Theme.textPrimary
                  }

                  DropShadow {
                    anchors.fill: logoText
                    source: logoText
                    visible: Theme.isDark
                    horizontalOffset: Theme.shadowHorizontalOffset
                    verticalOffset: Theme.shadowVerticalOffset
                    radius: Theme.shadowRadius
                    samples: 16
                    spread: 0
                    color: Theme.shadowColor
                  }

                  MouseArea {
                    id: logoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPressed: leftHi.pressed = true
                    onReleased: leftHi.pressed = false

                    onClicked: logoMenu.toggle()
                  }
                }

                // Workspace windows (pass the state object down)
                WorkspaceWindows {
                  height: parent.height
                  screen: modelData
                  highlightState: leftHi
                }
              }
            }

            // Logo Menu - positioned as a popup window
            Menu.MenuPopup {
              id: logoMenu
              anchorItem: logoRect
              yOffset: 8

              model: [
                { type: "action", icon: "􀙗", label: "About This Mac" },
                { type: "separator" },
                { type: "action", icon: "􀈎", label: "System Settings...", shortcut: ["􀆔", ","] },
                { type: "action", icon: "􁣡", label: "App Store..." },
                { type: "separator" },
                { type: "action", label: "Applications", submenu: [
                  { type: "action", label: "Finder" },
                  { type: "action", label: "Safari" },
                  { type: "action", label: "Terminal" }
                ]},
                { type: "action", label: "Documents", submenu: [
                  { type: "action", label: "Downloads" },
                  { type: "action", label: "Pictures" },
                  { type: "action", label: "Music" }
                ] },
                { type: "separator" },
                { type: "action", icon: "􀜗", label: "Force Quit...", shortcut: ["􀆕", "􀆔", "Q"] },
                { type: "separator" },
                { type: "action", icon: "􀎥", label: "Sleep" },
                { type: "action", icon: "􀆨", label: "Restart..." },
                { type: "action", icon: "􀷃", label: "Shut Down..." },
                { type: "separator" },
                { type: "action", icon: "􀙧", label: "Lock Screen", shortcut: ["􀆔", "Q"] },
                { type: "action", icon: "􀉩", label: "Log Out", shortcut: ["􀆝", "􀆔", "Q"] }
              ]

              onItemClicked: function(item, index) {
                console.log("Menu item clicked:", item.label)
              }
            }
            Connections {
              target: logoMenu
              function onVisibleChanged() {
                leftHi.activeTarget = logoMenu.visible ? logoRect : null
              }
            }

            // Spacer to push right section to the end
            Item {
              width: parent.width - leftSection.width - rightSection.width
              height: parent.height
            }

            // Right section - System controls
            Item {
              id: rightSection
              height: parent.height
              width: rightRow.implicitWidth
              function syncNotificationCenterHighlight() {
                var shouldHighlight = barPanelWindow.notificationCenterOpenProxy && barPanelWindow.notificationCenterTriggerItemProxy === timeDisplay
                if (shouldHighlight) {
                  rightHi.activeTarget = timeDisplay
                } else if (rightHi.activeTarget === timeDisplay) {
                  rightHi.activeTarget = null
                }
              }
              Component.onCompleted: syncNotificationCenterHighlight()
              Component.onDestruction: {
                if (rightHi.activeTarget === timeDisplay) {
                  rightHi.activeTarget = null
                }
              }

              QtObject {
                id: rightHi
                property Item activeTarget: null
                property Item pulseTarget: null
              }

              Connections {
                target: barPanelWindow
                function onNotificationCenterOpenProxyChanged() {
                  rightSection.syncNotificationCenterHighlight()
                }
                function onNotificationCenterTriggerItemProxyChanged() {
                  rightSection.syncNotificationCenterHighlight()
                }
              }

              Rectangle {
                id: rightPill
                z: 0
                radius: Theme.borderRadius

                property Item target: rightHi.activeTarget ?? rightHi.pulseTarget

                x: target ? target.mapToItem(rightSection, 0, 0).x - Theme.hoverOverlap : 0
                y: 0
                width: target ? target.width + (Theme.hoverOverlap * 2) : 0
                height: parent.height

                color: rightHi.activeTarget
                ? Qt.rgba(1, 1, 1, 0.10)
                : (rightHi.pulseTarget
                ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.70)
                : "transparent")

                opacity: target ? 1 : 0
              }

              Row {
                id: rightRow
                z: 1
                spacing: 0
                height: parent.height

                Widgets.SystemTrayArea {
                  height: parent.height
                  highlightState: rightHi
                  iconSize: Theme.iconSize
                }

                // IconButton { icon: "􀙇"; highlightState: rightHi; onClicked: {} }
                // IconButton { icon: "􀊫"; highlightState: rightHi; onClicked: {} }
                IconButton { icon: "􀜊"; highlightState: rightHi; onClicked: {} }

                TimeDisplay {
                  id: timeDisplay
                  height: parent.height
                  highlightState: rightHi
                  onClicked: barPanelWindow.toggleNotificationCenterForBar(timeDisplay)
                }
              }
            }
          }
        }
      }
    }
  }
}
