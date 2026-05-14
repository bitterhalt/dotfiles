from ignis import widgets
from ignis.services.hyprland import HyprlandService, HyprlandWorkspace
from ignis.services.niri import NiriService, NiriWorkspace
from modules.utils.workspace_utils import WorkspaceNameFormatter
from settings import config

hypr = HyprlandService.get_default()
niri = NiriService.get_default()

_show_focused_only: bool = getattr(config.ui.bar, "workspace_focused_only", False)


def _toggle_focused_only():
    global _show_focused_only
    _show_focused_only = not _show_focused_only
    if hypr.is_available:
        hypr.notify("workspaces")
    elif niri.is_available:
        niri.notify("workspaces")


class WorkspaceButton:
    @staticmethod
    def create_hyprland_button(ws: HyprlandWorkspace) -> widgets.Button:
        label_text = WorkspaceNameFormatter.format_hyprland_label(ws.name)

        btn = widgets.Button(
            css_classes=["ws-btn", "unset"],
            on_click=lambda *_: ws.switch_to(),
            on_right_click=lambda *_: _toggle_focused_only(),
            child=widgets.Label(label=label_text),
        )
        if ws.id == hypr.active_workspace.id:
            btn.add_css_class("active")
        return btn

    @staticmethod
    def create_niri_button(ws: NiriWorkspace) -> widgets.Button:
        ws_display = ws.name if hasattr(ws, "name") and ws.name else ws.idx
        label_text = WorkspaceNameFormatter.format_niri_label(ws_display)

        btn = widgets.Button(
            css_classes=["ws-btn", "unset"],
            on_click=lambda *_: ws.switch_to(),
            on_right_click=lambda *_: _toggle_focused_only(),
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


def _filter_hyprland(workspaces):
    """Return workspaces to display, honouring focused-only mode."""
    all_ws = [w for w in workspaces if w.id >= 1 or w.name == "special: scratchpad"]
    if _show_focused_only:
        return [w for w in all_ws if w.id == hypr.active_workspace.id]
    return all_ws


def _filter_niri(workspaces, monitor_name: str):
    """Return workspaces to display for a given output."""
    all_ws = [w for w in workspaces if w.output == monitor_name]
    if _show_focused_only:
        return [w for w in all_ws if w.is_active]
    return all_ws


class WorkspaceWidget:
    @staticmethod
    def _scroll_niri(output: str, delta: int):
        active = [w for w in niri.workspaces if w.output == output and w.is_active]
        if not active:
            return
        niri.switch_to_workspace(active[0].idx + delta)

    @staticmethod
    def create_hyprland_widget() -> widgets.EventBox:
        return widgets.EventBox(
            css_classes=["workspaces"],
            on_scroll_up=lambda *_: hypr.switch_to_workspace(
                hypr.active_workspace.id - 1
            ),
            on_scroll_down=lambda *_: hypr.switch_to_workspace(
                hypr.active_workspace.id + 1
            ),
            child=hypr.bind_many(
                ["workspaces", "active_workspace"],
                transform=lambda ws, active: [
                    WorkspaceButton.create(w) for w in _filter_hyprland(ws)
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
                transform=lambda ws: [
                    WorkspaceButton.create(w) for w in _filter_niri(ws, monitor_name)
                ],
            ),
        )

    @staticmethod
    def create(monitor_name: str) -> widgets.Widget:
        if hypr.is_available:
            return WorkspaceWidget.create_hyprland_widget()
        elif niri.is_available:
            return WorkspaceWidget.create_niri_widget(monitor_name)
        return widgets.Box(css_classes=["workspaces"])
