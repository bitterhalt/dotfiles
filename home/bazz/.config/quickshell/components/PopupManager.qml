import QtQuick

QtObject {
    id: manager

    property var current: null

    function toggle(popup) {
        const opening = !popup.visible;
        if (current && current !== popup)
            current.visible = false;

        popup.visible = opening;
        current = opening ? popup : null;
    }

    function close(popup) {
        popup.visible = false;
        if (current === popup)
            current = null;

    }

    function closeAll() {
        if (current)
            current.visible = false;

        current = null;
    }

}
