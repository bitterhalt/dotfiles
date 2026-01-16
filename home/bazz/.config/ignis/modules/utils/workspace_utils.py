from ignis.services.hyprland import HyprlandService
from ignis.services.niri import NiriService

hypr = HyprlandService.get_default()
niri = NiriService.get_default()


class WorkspaceNameFormatter:
    @staticmethod
    def get_workspace_name() -> str | None:
        if hypr.is_available:
            name = hypr.active_workspace.name
            if name.startswith("special: "):
                name = name.split(":")[-1].capitalize()
            return name

        if niri.is_available:
            return str(niri.active_workspace.idx)

        return None

    @staticmethod
    def format_hyprland_label(workspace_name: str) -> str:
        if workspace_name.isdigit():
            return workspace_name
        elif workspace_name.startswith("special:"):
            clean_name = workspace_name.split(":")[-1]
            return clean_name[0].upper()
        else:
            return workspace_name[0].upper()

    @staticmethod
    def format_niri_label(workspace_idx: int) -> str:
        return str(workspace_idx)
