pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import ".." as Root
import "../menu" as Menu

Item {
    id: root

    property var highlightState: null
    property int iconSize: Root.Theme.iconSize
    property int itemPadding: Root.Theme.itemPadding

    implicitWidth: trayRow.implicitWidth
    implicitHeight: trayRow.implicitHeight

    function clearActiveTarget(targetItem) {
        if (root.highlightState && root.highlightState.activeTarget === targetItem) {
            root.highlightState.activeTarget = null;
        }
    }

    function buildMenuModelFromEntries(sourceItems) {
        if (!sourceItems)
            return [];

        var model = [];

        for (var i = 0; i < sourceItems.length; i++) {
            var entry = sourceItems[i];
            if (!entry)
                continue;
            if (entry.isSeparator) {
                model.push({
                    type: "separator"
                });
                continue;
            }

            var item = {
                type: "action",
                label: entry.text,
                disabled: !entry.enabled,
                reserveCheckmark: entry.buttonType !== QsMenuButtonType.None,
                checked: entry.checkState === Qt.Checked,
                action: function (e) {
                    return function () {
                        e.triggered();
                    };
                }(entry)
            };

            if (entry.hasChildren) {
                item.submenu = root.buildMenuModelFromEntries(entry.children.values);
            }

            model.push(item);
        }

        return model;
    }

    Row {
        id: trayRow
        spacing: 0
        height: parent.height

        Repeater {
            model: SystemTray.items

            Item {
                id: delegateRoot
                required property var modelData
                property var trayItem: modelData
                property bool hasCustomMenu: trayItem && trayItem.hasMenu && trayItem.menu
                property real pendingMenuX: 0
                property real pendingMenuY: 0
                property int menuOpenRetryCount: 0

                function openCustomMenuAt(x, y) {
                    if (!delegateRoot.hasCustomMenu)
                        return;

                    delegateRoot.pendingMenuX = x;
                    delegateRoot.pendingMenuY = y + 8;
                    delegateRoot.menuOpenRetryCount = 0;
                    delegateRoot.tryOpenCustomMenu();
                }

                function tryOpenCustomMenu() {
                    var menuModel = root.buildMenuModelFromEntries(trayMenuOpener.children.values);
                    if (menuModel.length > 0) {
                        trayMenu.model = menuModel;
                        trayMenu.anchorPointX = delegateRoot.pendingMenuX;
                        trayMenu.anchorPointY = delegateRoot.pendingMenuY;
                        trayMenu.open();
                        return;
                    }

                    if (delegateRoot.menuOpenRetryCount >= 8)
                        return;

                    delegateRoot.menuOpenRetryCount++;
                    menuOpenRetryTimer.restart();
                }

                QsMenuOpener {
                    id: trayMenuOpener
                    menu: delegateRoot.hasCustomMenu ? delegateRoot.trayItem.menu : null
                }

                Timer {
                    id: menuOpenRetryTimer
                    interval: 16
                    repeat: false
                    onTriggered: delegateRoot.tryOpenCustomMenu()
                }

                width: root.iconSize + (root.itemPadding * 2)
                height: trayRow.height

                IconImage {
                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize
                    source: delegateRoot.trayItem ? delegateRoot.trayItem.icon : ""
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: function (mouse) {
                        if (!delegateRoot.trayItem)
                            return;
                        if (mouse.button === Qt.LeftButton) {
                            if (delegateRoot.trayItem.onlyMenu && delegateRoot.hasCustomMenu) {
                                delegateRoot.openCustomMenuAt(mouse.x, mouse.y);
                                return;
                            }
                            delegateRoot.trayItem.activate();
                            return;
                        }

                        if (mouse.button === Qt.MiddleButton) {
                            delegateRoot.trayItem.secondaryActivate();
                            return;
                        }

                        if (mouse.button === Qt.RightButton && delegateRoot.hasCustomMenu) {
                            delegateRoot.openCustomMenuAt(mouse.x, mouse.y);
                        }
                    }
                }

                WheelHandler {
                    onWheel: function (event) {
                        if (!delegateRoot.trayItem)
                            return;
                        if (event.angleDelta.x !== 0) {
                            delegateRoot.trayItem.scroll(event.angleDelta.x, true);
                        }
                        if (event.angleDelta.y !== 0) {
                            delegateRoot.trayItem.scroll(event.angleDelta.y, false);
                        }
                        event.accepted = true;
                    }
                }

                Menu.MenuPopup {
                    id: trayMenu
                    anchorItem: delegateRoot
                    yOffset: 8
                    adaptiveWidth: true
                    model: []
                }

                Connections {
                    target: trayMenu
                    function onVisibleChanged() {
                        if (!root.highlightState)
                            return;
                        if (trayMenu.visible)
                            root.highlightState.activeTarget = delegateRoot;
                        else
                            root.clearActiveTarget(delegateRoot);
                    }
                }

                Component.onDestruction: {
                    root.clearActiveTarget(delegateRoot);
                }
            }
        }
    }
}
