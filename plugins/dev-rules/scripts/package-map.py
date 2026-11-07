#!/usr/bin/env python3
"""Writes a structure map of each named directory for review-code's design reviewer.

Usage: package-map.py <dir>...

Prints MAP=<path> (the map) and FILES=<path> (the files mapped, one per line). Both are
written to $REVIEW_DIFF_DIR, else $TMPDIR/dev-rules. Languages are read by the
extractors in package_map/extractors/.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from package_map.core import Repository, build_map, render  # noqa: E402


def main(argv: list) -> int:
    if not argv:
        print("usage: package-map.py <dir>...", file=sys.stderr)
        return 2
    root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], check=True, capture_output=True, text=True
        ).stdout.strip()
    )
    out_dir = Path(
        os.environ.get("REVIEW_DIFF_DIR")
        or Path(os.environ.get("TMPDIR", "/tmp")) / "dev-rules"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    repository = Repository(root)
    maps = [build_map(repository, directory) for directory in argv]
    fd, map_path = tempfile.mkstemp(prefix="package-map-", suffix=".md", dir=out_dir)
    with os.fdopen(fd, "w") as handle:
        handle.write("\n".join(render(m) for m in maps))
    files_path = map_path[: -len(".md")] + ".files"
    Path(files_path).write_text("".join(f.path + "\n" for m in maps for f in m.files))
    print(f"MAP={map_path}")
    print(f"FILES={files_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
