import subprocess
import sys
from pathlib import Path

import pytest

from package_map.core import Repository, build_map, render

SCRIPT = Path(__file__).resolve().parents[2] / "plugins/dev-rules/scripts/package-map.py"


def write(root: Path, path: str, text: str) -> None:
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    root.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    write(
        root,
        "a/p/Box.kt",
        "package a.p\n"
        "\n"
        "import b.q.Thing\n"
        "\n"
        "class Box(val width: Int) {\n"
        "    fun area(): Int = width\n"
        "}\n"
        "\n"
        "private class Hidden\n"
        "\n"
        "internal fun unusedHelperXyz() = 1\n",
    )
    write(root, "a/p/notes.txt", "not Kotlin\n")
    write(
        root,
        "b/q/Thing.kt",
        "package b.q\n\nimport a.p.Box\n\nclass Thing {\n    val box = Box(1).area()\n}\n",
    )
    write(root, "only/sub/Leaf.kt", "package only.sub\n")
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    return root


def test_counts_other_files_that_mention_each_name(repo: Path):
    directory_map = build_map(Repository(repo), "a/p")

    assert directory_map.references == {
        ("a/p/Box.kt", "Box"): 1,
        ("a/p/Box.kt", "width"): 0,
        ("a/p/Box.kt", "area"): 1,
        ("a/p/Box.kt", "unusedHelperXyz"): 0,
    }


def test_finds_imports_both_ways_as_a_cycle(repo: Path):
    directory_map = build_map(Repository(repo), "a/p")

    assert directory_map.packages == ("a.p",)
    assert directory_map.imports_from == (("b.q", 1),)
    assert directory_map.imported_by == (("b.q", 1),)
    assert directory_map.cycles == ("b.q",)


def test_names_files_without_an_extractor(repo: Path):
    directory_map = build_map(Repository(repo), "a/p")

    assert directory_map.unsupported_extensions == (".txt",)
    assert [f.path for f in directory_map.files] == ["a/p/Box.kt", "a/p/notes.txt"]


def test_renders_declarations_members_and_counts(repo: Path):
    text = render(build_map(Repository(repo), "a/p"))

    assert "- a/p/Box.kt (11 lines)\n  - class Box — 1\n    - val width — 0\n    - fun area — 1\n" in text
    assert "  - private class Hidden\n" in text
    assert "  - internal fun unusedHelperXyz — 0\n" in text
    assert "No extractor for: .txt — read those files to judge them.\n" in text
    assert "## Both ways (a dependency cycle)\n\n- b.q\n" in text


def test_maps_a_directory_holding_only_a_child_directory(repo: Path):
    text = render(build_map(Repository(repo), "only"))

    assert "## Files (0)\n" in text
    assert "- only/sub/ (1 files)\n" in text


def run_script(repo: Path, out_dir: Path, *directories: str) -> dict:
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *directories],
        cwd=repo,
        env={"REVIEW_DIFF_DIR": str(out_dir), "PATH": "/usr/bin:/bin"},
        check=True,
        capture_output=True,
        text=True,
    )
    return dict(line.split("=", 1) for line in result.stdout.splitlines())


def test_script_writes_the_map_and_the_files_list(repo: Path, tmp_path: Path):
    printed = run_script(repo, tmp_path / "out", "a/p", "only")

    map_text = Path(printed["MAP"]).read_text()
    assert map_text.startswith("# a/p\n")
    assert "# only\n" in map_text
    assert Path(printed["FILES"]).read_text() == "a/p/Box.kt\na/p/notes.txt\n"


def test_each_run_writes_its_own_map(repo: Path, tmp_path: Path):
    first = run_script(repo, tmp_path / "out", "a/p")
    second = run_script(repo, tmp_path / "out", "a/p")

    assert first["MAP"] != second["MAP"]
