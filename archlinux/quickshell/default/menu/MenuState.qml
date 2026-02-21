pragma Singleton

import Quickshell

Singleton {
    property var activeTopMenu: null

    function requestOpen(menu) {
        if (activeTopMenu && activeTopMenu !== menu) {
            activeTopMenu.close()
        }
        activeTopMenu = menu
    }

    function clearIfCurrent(menu) {
        if (activeTopMenu === menu) {
            activeTopMenu = null
        }
    }
}
