pragma ComponentBehavior: Bound

import QtQuick
import "../components"

// Personal launcher actions live in launcher/UserActions.qml; built-in shell
// actions live in components/QuickshellActions.qml. Both are merged here so the
// rest of the launcher searches a single list.
Item {
    id: root

    visible: false

    // Personal actions, normalized to the same shape as the built-in ones.
    readonly property var userActions: user.actions.map(action => ({
                label: action.label,
                keyword: action.keyword.trim().toLowerCase(),
                command: action.command,
                confirm: action.confirm === undefined ? true : action.confirm,
                category: action.category.trim(),
                icon: action.icon || ""
            }))

    // Everything the launcher searches: built-in shell actions first, then personal.
    readonly property var actions: builtin.actions.concat(userActions)

    QuickshellActions {
        id: builtin
    }

    UserActions {
        id: user
    }
}
