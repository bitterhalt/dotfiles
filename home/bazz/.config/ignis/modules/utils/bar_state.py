import json
from pathlib import Path
from typing import Optional


class BarStateManager:
    def __init__(self, state_file: Path):
        self.state_file = state_file
        self.state_file.parent.mkdir(parents=True, exist_ok=True)

    def save_state(self, visible: bool) -> bool:
        try:
            self.state_file.parent.mkdir(parents=True, exist_ok=True)

            with open(self.state_file, "w") as f:
                json.dump({"visible": visible}, f, indent=2)

            return True
        except Exception as e:
            print(f"Failed to save bar state: {e}")
            return False

    def load_state(self) -> Optional[bool]:
        if not self.state_file.exists():
            return None

        try:
            with open(self.state_file) as f:
                data = json.load(f)
            return data.get("visible", None)
        except Exception as e:
            print(f"Failed to load bar state: {e}")
            return None

    def clear_state(self) -> bool:
        try:
            if self.state_file.exists():
                self.state_file.unlink()
            return True
        except Exception as e:
            print(f"Failed to clear bar state: {e}")
            return False


_state_manager: Optional[BarStateManager] = None


def get_bar_state_manager() -> BarStateManager:
    global _state_manager

    if _state_manager is None:
        from settings import config

        state_file = config.paths.data_dir / "bar_state.json"
        _state_manager = BarStateManager(state_file)

    return _state_manager


def save_bar_state(visible: bool):
    from settings import config

    if not config.ui.bar_remember_state:
        return
    manager = get_bar_state_manager()
    manager.save_state(visible)


def load_bar_state() -> bool:
    from settings import config

    if not config.ui.bar_remember_state:
        return True

    manager = get_bar_state_manager()
    saved_state = manager.load_state()

    if saved_state is None:
        return True

    return saved_state
