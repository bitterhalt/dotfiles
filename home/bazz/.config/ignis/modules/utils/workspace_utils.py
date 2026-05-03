from ignis.services.hyprland import HyprlandService
from ignis.services.niri import NiriService

hypr = HyprlandService.get_default()
niri = NiriService.get_default()


class WorkspaceNameFormatter:
    def get_workspace_name() -> str | None:
        """Get workspace name from either Hyprland or Niri"""
        if hypr.is_available:
            name = hypr.active_workspace.name
            if name.startswith("special: "):
                name = name.split(":")[-1].capitalize()
            return name

        if niri.is_available:
            active_workspaces = [w for w in niri.workspaces if w.is_active]
            if active_workspaces:
                ws = active_workspaces[0]
                if hasattr(ws, "name") and ws.name:
                    return ws.name
                return str(ws.idx)
            return None

        return None

    def format_hyprland_label(workspace_name: str) -> str:
        if workspace_name.isdigit():
            return workspace_name
        elif workspace_name.startswith("special:"):
            clean_name = workspace_name.split(":")[-1]
            return clean_name[0].upper()
        else:
            return workspace_name

    def format_niri_label(workspace_name_or_idx) -> str:
        if isinstance(workspace_name_or_idx, str):
            return workspace_name_or_idx
        return str(workspace_name_or_idx)
