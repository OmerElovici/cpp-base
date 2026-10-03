#!/usr/bin/env python3
"""Create a named copy of this C++ template."""

import argparse
from pathlib import Path
import re
import shutil

TEMPLATE_ITEMS = {
    "CMakeLists.txt", "CMakePresets.json", "Dependencies.cmake", "ProjectOptions.cmake",
    "justfile", ".clangd", ".clang-format", ".clang-tidy", ".gitignore", ".vscode",
    "cmake", "src", "include", "tests", "LICENSE", "LICENSE.txt", "LICENSE.md", ".gitattributes",
}
EXCLUDED = {".cache", "out", ".git"}


def generate_project(name: str, destination: Path) -> Path:
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", name):
        raise ValueError("Project name must start with a letter and contain only letters, digits or underscores")
    template = Path(__file__).resolve().parent
    destination = destination.expanduser().absolute()
    if destination.resolve().is_relative_to(template):
        raise ValueError("Destination must be outside the template directory")

    def rename(text):
        return re.sub(r"myproject|MYPROJECT",
                      lambda match: name.upper() if match[0] == "MYPROJECT" else name, text)

    def copy(source, target):
        if source.name in EXCLUDED:
            return
        if source.is_symlink():
            raise ValueError(f"Cannot copy source symlink: {source}")
        if source.is_dir():
            target.mkdir()
            for child in source.iterdir():
                copy(child, target / rename(child.name))
        else:
            content = source.read_bytes()
            try:
                content = rename(content.decode("utf-8")).encode("utf-8")
            except UnicodeDecodeError:
                pass
            with target.open("xb") as output:
                output.write(content)

    destination.mkdir(parents=True)
    try:
        for source in template.iterdir():
            if source.name in TEMPLATE_ITEMS:
                copy(source, destination / rename(source.name))
    except BaseException:
        shutil.rmtree(destination)
        raise
    return destination


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name", help="Project identifier")
    parser.add_argument("destination", type=Path, help="New project folder")
    args = parser.parse_args()
    try:
        destination = generate_project(args.name, args.destination)
    except (ValueError, OSError) as error:
        parser.exit(1, f"error: {error}\n")
    print(f"Created {args.name} in {destination}")
