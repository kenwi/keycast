#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
control = root / "scripts" / "bridge-control"
expected = f'pcall(dofile, "{root / "bridge.lua"}")'


def run(env, *args):
    result = subprocess.run(
        [str(control), *args],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    payload = json.loads(result.stdout)
    return result.returncode, payload


def write_config(folder, body):
    hypr = folder / "hypr"
    hypr.mkdir()
    path = hypr / "hyprland.lua"
    path.write_text(body, encoding="utf-8")
    return path


with tempfile.TemporaryDirectory() as raw:
    folder = Path(raw)
    env = os.environ.copy()
    env["XDG_CONFIG_HOME"] = str(folder)
    env["XDG_STATE_HOME"] = str(folder / "state")
    write_config(
        folder,
        "-- user\n"
        "-- >>> Keycast managed bridge >>>\n"
        'pcall(dofile, "/old/path/local.keycast/bridge.lua")\n'
        "-- <<< Keycast managed bridge <<<\n",
    )
    code, inspect = run(env, "inspect")
    assert code == 0, inspect
    assert inspect["managedBlockState"] == "stale", inspect
    assert inspect["safeToPatch"] is True, inspect
    code, enabled = run(env, "enable")
    assert code == 0, enabled
    assert enabled["managedBlockState"] == "present", enabled
    text = (folder / "hypr" / "hyprland.lua").read_text(encoding="utf-8")
    assert expected in text, text
    assert text.count("-- >>> Keycast managed bridge >>>") == 1, text

print("control ok")
