"""
tree_gen.py — Generate a project file tree for thesis documentation.

Usage:
    python tree_gen.py

Output:
    - Prints tree to console
    - Saves tree to project_tree.txt (overwrite)
"""

import os
import fnmatch
from pathlib import Path

# ── Configuration ──────────────────────────────────────────────────────────────

ROOT = Path(__file__).parent

EXCLUDE_DIRS = {
    # Platforms not used
    "build",
    "ios",
    "linux",
    "macos",
    "web",
    "windows",
    # IDE / VCS
    ".dart_tool",
    ".idea",
    ".git",
    # Android cache
    ".gradle",
    ".kotlin",
    # Android build variant source sets (only contain manifest duplicates)
    "debug",
    "profile",
    # Android build tooling & resources (not relevant for thesis)
    "gradle",
    "res",
    "java",
}

EXCLUDE_FILE_PATTERNS = [
    # Generated files
    "pubspec.lock",
    "*.g.dart",
    "GeneratedPluginRegistrant.java",
    # Local machine config
    "local.properties",
    "*.iml",
    ".metadata",
    ".flutter-plugins-dependencies",
    ".gitignore",
    # Dev tooling config
    "derry.yaml",
    "devtools_options.yaml",
    # Sensitive signing files
    "key.properties",
    "*.jks",
    # Gradle binary & build config
    "gradle-wrapper.jar",
    "build.gradle.kts",
    "gradle.properties",
    "gradlew",
    "gradlew.bat",
    "settings.gradle.kts",
    "proguard-rules.pro",
    # Agent / tree tools
    "AGENTS.md",
    "struktur.txt",
    "tree_gen.py",
    "project_tree.txt",
]

OUTPUT_FILE = ROOT / "project_tree.txt"

# ── Helpers ────────────────────────────────────────────────────────────────────


def is_excluded_file(name: str) -> bool:
    return any(fnmatch.fnmatch(name, pat) for pat in EXCLUDE_FILE_PATTERNS)


def sorted_entries(path: Path):
    """Return entries sorted: directories first, then files, both alphabetical."""
    dirs, files = [], []
    for entry in sorted(path.iterdir(), key=lambda e: e.name.lower()):
        if entry.is_dir():
            if entry.name not in EXCLUDE_DIRS:
                dirs.append(entry)
        else:
            if not is_excluded_file(entry.name):
                files.append(entry)
    return dirs + files


def generate_tree(path: Path, prefix: str = "") -> list[str]:
    lines = []
    entries = sorted_entries(path)
    for i, entry in enumerate(entries):
        is_last = i == len(entries) - 1
        connector = "└── " if is_last else "├── "
        if entry.is_dir():
            lines.append(f"{prefix}{connector}{entry.name}/")
            extension = "    " if is_last else "│   "
            lines.extend(generate_tree(entry, prefix + extension))
        else:
            lines.append(f"{prefix}{connector}{entry.name}")
    return lines


# ── Main ───────────────────────────────────────────────────────────────────────


def main():
    header = f"{ROOT.name}/"
    tree_lines = generate_tree(ROOT)
    output = "\n".join([header] + tree_lines)

    # Print to console
    print(output)

    # Save to file
    OUTPUT_FILE.write_text(output, encoding="utf-8")
    print(f"\n✓ Saved to {OUTPUT_FILE.name}")


if __name__ == "__main__":
    main()
