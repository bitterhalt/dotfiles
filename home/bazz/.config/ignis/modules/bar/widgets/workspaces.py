from ignis import widgets
from ignis.services.hyprland import HyprlandService, HyprlandWorkspace
from ignis.services.niri import NiriService, NiriWorkspace
from modules.utils.workspace_utils import WorkspaceNameFormatter

hypr = HyprlandService.get_default()
niri = NiriService.get_default()


class WorkspaceButton:
    @staticmethod
    def create_hyprland_button(ws: HyprlandWorkspace) -> widgets.Button:
        """Create a button for a Hyprland workspace."""
        label_text = WorkspaceNameFormatter.format_hyprland_label(ws.name)

        btn = widgets.Button(
            css_classes=["ws-btn", "unset"],
            on_click=lambda *_: ws.switch_to(),
            child=widgets.Label(label=label_text),
        )
        if ws.id == hypr.active_workspace.id:
            btn.add_css_class("active")
        return btn

    @staticmethod
    def create_niri_button(ws: NiriWorkspace) -> widgets.Button:
        """Create a button for a Niri workspace."""
        label_text = WorkspaceNameFormatter.format_niri_label(ws.idx)

        btn = widgets.Button(
            css_classes=["ws-btn", "unset"],
            on_click=lambda *_: ws.switch_to(),
            child=widgets.Label(label=label_text),
        )
        if ws.is_active:
            btn.add_css_class("active")
        return btn

    @staticmethod
    def create(ws) -> widgets.Button:
        if hypr.is_available:
            return WorkspaceButton.create_hyprland_button(ws)
        elif niri.is_available:
            return WorkspaceButton.create_niri_button(ws)
        return widgets.Button(css_classes=["ws-btn", "unset"])


class WorkspaceWidget:
    @staticmethod
    def _scroll_niri(output: str, delta: int):
        """Handle scroll events for Niri workspaces."""
        active = [w for w in niri.workspaces if w.output == output and w.is_active]
        if not active:
            return
        niri.switch_to_workspace(active[0].idx + delta)

    @staticmethod
    def create_hyprland_widget() -> widgets.EventBox:
        return widgets.EventBox(
            css_classes=["workspaces"],
            on_scroll_up=lambda *_: hypr.switch_to_workspace(hypr.active_workspace.id - 1),
            on_scroll_down=lambda *_: hypr.switch_to_workspace(hypr.active_workspace.id + 1),
            child=hypr.bind_many(
                ["workspaces", "active_workspace"],
                transform=lambda ws, active: [
                    WorkspaceButton.create(w) for w in ws if w.id >= 1 or w.name == "special: scratchpad"
                ],
            ),
        )

    @staticmethod
    def create_niri_widget(monitor_name: str) -> widgets.EventBox:
        return widgets.EventBox(
            css_classes=["workspaces"],
            on_scroll_up=lambda *_: WorkspaceWidget._scroll_niri(monitor_name, +1),
            on_scroll_down=lambda *_: WorkspaceWidget._scroll_niri(monitor_name, -1),
            child=niri.bind(
                "workspaces",
                transform=lambda ws: [WorkspaceButton.create(w) for w in ws if w.output == monitor_name],
            ),
        )

    @staticmethod
    def create(monitor_name: str) -> widgets.Widget:
        if hypr.is_available:
            return WorkspaceWidget.create_hyprland_widget()
        elif niri.is_available:
            return WorkspaceWidget.create_niri_widget(monitor_name)
        return widgets.Box(css_classes=["workspaces"])
