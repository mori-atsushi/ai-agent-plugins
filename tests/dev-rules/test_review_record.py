import json
import os
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[2] / "plugins/dev-rules/scripts/review-record.sh"


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    rules = root / ".agents/rules"
    rules.mkdir(parents=True)
    (rules / "editor.md").write_text(
        "---\n"
        "description: Editor rules\n"
        "perspectives:\n"
        "  - design\n"
        "paths:\n"
        '  - "src/**/*.kt"\n'
        "---\n"
        "\n"
        "- [ED-1] **A rule.**\n"
    )
    write_rule(rules / "naming.md", "design")
    write_rule(rules / "fixtures.md", "test")
    (root / "src").mkdir()
    (root / "src/Main.kt").write_text("class Main\n")
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    return root


def write_rule(path: Path, perspective: str) -> None:
    path.write_text(
        "---\n"
        "description: A rule file without IDs\n"
        "perspectives:\n"
        f"  - {perspective}\n"
        "paths:\n"
        '  - "src/**/*.kt"\n'
        "---\n"
        "\n"
        "Only prose.\n"
    )


def run(repo: Path, tmp_path: Path, *args: str, stdin: str = "") -> subprocess.CompletedProcess:
    env = {**os.environ, "DEV_RULES_REVIEWS": str(tmp_path / "reviews")}
    return subprocess.run(
        ["bash", str(SCRIPT), *args], cwd=repo, env=env, input=stdin, capture_output=True, text=True
    )


def new_record(repo: Path, tmp_path: Path) -> str:
    result = run(repo, tmp_path, "new", "--skill", "review-code", "--perspective", "design", "src/Main.kt")
    assert result.returncode == 0, result.stderr
    return result.stdout.strip().removeprefix("RECORD=")


def finding(grounds: list[str]) -> str:
    return json.dumps(
        {
            "perspectives": ["design"],
            "severity": "low",
            "location": "src/Main.kt:1",
            "issue": "x",
            "grounds": grounds,
            "triage": "in-scope",
        }
    )


def test_new_rejects_a_second_perspective_name_after_one_flag(repo: Path, tmp_path: Path):
    result = run(repo, tmp_path, "new", "--skill", "review-plan", "--perspective", "design", "spec")

    assert result.returncode == 1
    assert 'no file or directory "spec"; give each perspective its own --perspective' in result.stderr


def test_new_records_each_repeated_perspective(repo: Path, tmp_path: Path):
    result = run(
        repo, tmp_path, "new", "--skill", "review-plan", "--perspective", "design", "--perspective", "spec"
    )

    record = json.loads(Path(result.stdout.strip().removeprefix("RECORD=")).read_text())
    assert set(record["applicable"]) == {"design", "spec"}


def test_add_asks_for_ids_when_a_rule_file_with_ids_is_cited(repo: Path, tmp_path: Path):
    record = new_record(repo, tmp_path)

    result = run(repo, tmp_path, "add", record, stdin=finding([".agents/rules/editor.md"]) + "\n")

    assert result.returncode == 1
    assert (
        'grounds ".agents/rules/editor.md" is a rule file with IDs; '
        "cite the ID of a rule in it that design applied, not its path"
    ) in result.stderr


def test_add_asks_for_ids_when_a_plugin_rule_file_is_cited(repo: Path, tmp_path: Path):
    record = new_record(repo, tmp_path)

    result = run(repo, tmp_path, "add", record, stdin=finding(["rules/general.md"]) + "\n")

    assert result.returncode == 1
    assert 'grounds "rules/general.md" is a rule file with IDs' in result.stderr


def test_add_accepts_the_path_of_an_applied_rule_file_without_ids(repo: Path, tmp_path: Path):
    record = new_record(repo, tmp_path)

    result = run(repo, tmp_path, "add", record, stdin=finding([".agents/rules/naming.md"]) + "\n")

    assert result.returncode == 0, result.stderr


def test_add_rejects_a_rule_file_without_ids_the_perspective_did_not_apply(
    repo: Path, tmp_path: Path
):
    record = new_record(repo, tmp_path)

    result = run(repo, tmp_path, "add", record, stdin=finding([".agents/rules/fixtures.md"]) + "\n")

    assert result.returncode == 1
    assert 'rule ".agents/rules/fixtures.md" is not one that design applied' in result.stderr


def test_add_accepts_the_id_of_an_applied_rule(repo: Path, tmp_path: Path):
    record = new_record(repo, tmp_path)

    result = run(repo, tmp_path, "add", record, stdin=finding(["ED-1"]) + "\n")

    assert result.returncode == 0, result.stderr
