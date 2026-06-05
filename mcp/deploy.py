#!/usr/bin/env python3
# /// script
# requires-python = ">=3.8"
# dependencies = [
#   "tomli; python_version < '3.11'",
# ]
# ///
"""
MCP Deploy Script
=================
Reads canonical MCP registrations from the dotfiles MCP store and merges them
into each tool's live config. Only adds missing servers — never overwrites
existing ones unless --force is used.

Usage:
  python mcp/deploy.py                         # deploy to all tools
  python mcp/deploy.py --tool claude-code      # single tool
  python mcp/deploy.py --dry-run               # preview without writing
  python mcp/deploy.py --no-expand             # keep ${VAR} literals
  python mcp/deploy.py --force                 # overwrite existing entries
  python mcp/deploy.py --force --server NAME   # rotate a single key

Supported tools: claude-code, gemini-cli, antigravity, codex-cli
"""

import argparse
import json
import os
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib  # provided by uv run on Python < 3.11 (PEP 723)
    except ImportError:
        tomllib = None  # TOML unavailable — codex-cli deploy will fail gracefully

# -- Paths --------------------------------------------------------------------

# The MCP store lives alongside this script inside the dotfiles repo.
SCRIPT_DIR = Path(__file__).resolve().parent
MCP_ROOT = SCRIPT_DIR  # dotfiles/mcp/

HOME = Path.home()

TOOL_CONFIGS = {
    "claude-code": {
        "registration": str(MCP_ROOT / "registrations" / "claude-code.json"),
        "live_config": str(HOME / ".claude" / "settings.json"),
        "format": "json",
        "mcp_key": "mcpServers",
    },
    "gemini-cli": {
        "registration": str(MCP_ROOT / "registrations" / "gemini-cli.json"),
        "live_config": str(HOME / ".gemini" / "settings.json"),
        "format": "json",
        "mcp_key": "mcpServers",
    },
    "antigravity": {
        "registration": str(MCP_ROOT / "registrations" / "antigravity.json"),
        "live_config": str(HOME / ".gemini" / "antigravity" / "mcp_config.json"),
        "format": "json",
        "mcp_key": "mcpServers",
    },
    "codex-cli": {
        "registration": str(MCP_ROOT / "registrations" / "codex-cli.json"),
        "live_config": str(HOME / ".codex" / "config.toml"),
        "format": "toml",
        "mcp_key": "mcp_servers",
    },
}

# -- Helpers ------------------------------------------------------------------

def expand_env_vars(obj):
    """Recursively expand ${VAR} references using system env vars."""
    if isinstance(obj, str):
        def replacer(m):
            key = m.group(1)
            val = os.environ.get(key)
            if val is None:
                print(f"  WARNING: env var ${{{key}}} not set -- keeping literal", file=sys.stderr)
                return m.group(0)
            return val
        return re.sub(r"\$\{([^}]+)\}", replacer, obj)
    elif isinstance(obj, dict):
        return {k: expand_env_vars(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [expand_env_vars(i) for i in obj]
    return obj


def strip_meta(d: dict) -> dict:
    """Remove underscore-prefixed meta/comment keys from a dict."""
    return {k: v for k, v in d.items() if not k.startswith("_")}


def load_registration(path: str) -> dict:
    """Load a registration JSON and return the mcpServers dict (meta keys stripped)."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    servers = data.get("mcpServers", {})
    return {name: strip_meta(cfg) for name, cfg in servers.items()}


def backup(path: str) -> str:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    bak = f"{path}.bak.{ts}"
    shutil.copy2(path, bak)
    return bak

# -- JSON deploy --------------------------------------------------------------

def deploy_json(tool_name: str, tc: dict, servers: dict, dry_run: bool, expand: bool, force: bool = False):
    live_path = tc["live_config"]
    mcp_key = tc["mcp_key"]

    if not Path(live_path).exists():
        print(f"  ERROR: live config not found: {live_path}")
        return

    with open(live_path, encoding="utf-8") as f:
        config = json.load(f)

    if mcp_key not in config:
        config[mcp_key] = {}

    added, updated, skipped = [], [], []
    for name, cfg in servers.items():
        resolved = expand_env_vars(cfg) if expand else cfg
        if name in config[mcp_key]:
            if force:
                config[mcp_key][name] = resolved
                updated.append(name)
            else:
                skipped.append(name)
            continue
        config[mcp_key][name] = resolved
        added.append(name)

    if added:
        print(f"  + Adding:   {', '.join(added)}")
    if updated:
        print(f"  ~ Updating: {', '.join(updated)}")
    if skipped:
        print(f"  = Skipping (already present): {', '.join(skipped)}")
    if not added and not updated:
        print("  No changes needed.")
        return

    if not dry_run:
        bak = backup(live_path)
        print(f"  Backed up to: {Path(bak).name}")
        with open(live_path, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)
        print(f"  Written: {live_path}")

# -- TOML deploy --------------------------------------------------------------

def toml_str(s: str) -> str:
    """Escape a string for use in a TOML basic string (double-quoted)."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def server_to_toml_block(name: str, cfg: dict) -> str:
    """Render an mcp_servers TOML block for a single server."""
    lines = [f"[mcp_servers.{name}]"]
    if "url" in cfg:
        lines.append(f'url = "{toml_str(cfg["url"])}"')
    if "command" in cfg:
        lines.append(f'command = "{toml_str(cfg["command"])}"')
    if "args" in cfg:
        args_str = ", ".join(f'"{toml_str(a)}"' for a in cfg["args"])
        lines.append(f"args = [{args_str}]")
    if "env" in cfg:
        for k, v in cfg["env"].items():
            lines.append(f'# env.{k} = "{toml_str(v)}"  # Set as system env var instead')
    return "\n".join(lines)


def deploy_toml(tool_name: str, tc: dict, servers: dict, dry_run: bool, expand: bool, force: bool = False):
    live_path = tc["live_config"]

    if not Path(live_path).exists():
        print(f"  ERROR: live config not found: {live_path}")
        return

    if tomllib is None:
        print("  ERROR: tomllib not available.")
        print("  Fix: upgrade to Python 3.11+, or: pip install tomli")
        return

    with open(live_path, "rb") as f:
        current = tomllib.load(f)

    existing = current.get("mcp_servers", {})

    with open(live_path, encoding="utf-8") as f:
        raw_text = f.read()

    added, updated, skipped = [], [], []
    new_blocks = []
    for name, cfg in servers.items():
        resolved_cfg = expand_env_vars(cfg) if expand else cfg
        if name in existing:
            if force:
                pattern = re.compile(
                    rf"(\[mcp_servers\.{re.escape(name)}\][^\[]*)", re.DOTALL
                )
                block = server_to_toml_block(name, resolved_cfg) + "\n"
                raw_text = pattern.sub(block, raw_text)
                updated.append(name)
            else:
                skipped.append(name)
            continue
        new_blocks.append(server_to_toml_block(name, resolved_cfg))
        added.append(name)

    if added:
        print(f"  + Adding:   {', '.join(added)}")
    if updated:
        print(f"  ~ Updating: {', '.join(updated)}")
    if skipped:
        print(f"  = Skipping (already present): {', '.join(skipped)}")
    if not added and not updated:
        print("  No changes needed.")
        return

    if not dry_run:
        bak = backup(live_path)
        print(f"  Backed up to: {Path(bak).name}")
        if new_blocks:
            raw_text = raw_text.rstrip("\n") + "\n\n" + "\n\n".join(new_blocks) + "\n"
        with open(live_path, "w", encoding="utf-8") as f:
            f.write(raw_text)
        print(f"  Written: {live_path}")

# -- Main ---------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Deploy canonical MCP server configs to each tool's live config."
    )
    parser.add_argument(
        "--tool",
        choices=list(TOOL_CONFIGS.keys()),
        help="Deploy to a specific tool only.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without writing files.",
    )
    parser.add_argument(
        "--no-expand",
        action="store_true",
        help="Keep ${VAR} literals -- use for tools that expand env vars at runtime.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing server entries. Use for key rotation or config updates.",
    )
    parser.add_argument(
        "--server",
        metavar="NAME",
        help="Only deploy this server name (filter). Combine with --force to rotate a single key.",
    )
    args = parser.parse_args()

    targets = [args.tool] if args.tool else list(TOOL_CONFIGS.keys())
    expand = not args.no_expand

    if args.dry_run:
        print("-- DRY RUN -- no files will be written --\n")
    if args.force:
        print("-- FORCE mode -- existing entries will be overwritten --\n")

    for tool_name in targets:
        tc = TOOL_CONFIGS[tool_name]
        reg_path = tc["registration"]

        print(f"[{tool_name}]")

        if not Path(reg_path).exists():
            print(f"  ERROR: registration not found: {reg_path}")
            print()
            continue

        servers = load_registration(reg_path)

        # Merge local overlay if present (mcp/local/ is gitignored — use for
        # machine-specific or private servers not tracked in the repo).
        local_reg_path = MCP_ROOT / "local" / "registrations" / f"{tool_name}.json"
        if local_reg_path.exists():
            local_servers = load_registration(str(local_reg_path))
            if local_servers:
                print(f"  Local overlay: +{len(local_servers)} private server(s) from mcp/local/")
                servers = {**servers, **local_servers}

        if args.server:
            if args.server not in servers:
                print(f"  '{args.server}' not in registration -- skipping")
                print()
                continue
            servers = {args.server: servers[args.server]}

        print(f"  Registration: {len(servers)} server(s) to process")

        if tc["format"] == "json":
            deploy_json(tool_name, tc, servers, args.dry_run, expand, force=args.force)
        elif tc["format"] == "toml":
            deploy_toml(tool_name, tc, servers, args.dry_run, expand, force=args.force)

        print()


if __name__ == "__main__":
    main()
