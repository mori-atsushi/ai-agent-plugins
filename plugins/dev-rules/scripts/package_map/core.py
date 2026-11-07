"""Builds and renders the structure map of a directory."""

from __future__ import annotations

import re
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

from . import extractors
from .extractors import Declaration, FileFacts

_WORD = re.compile(r"[A-Za-z_]\w*")


@dataclass(frozen=True)
class FileEntry:
    path: str
    lines: int
    facts: Optional[FileFacts]  # None when no extractor reads the file


@dataclass(frozen=True)
class DirectoryMap:
    directory: str
    packages: tuple[str, ...]
    files: tuple[FileEntry, ...]
    unsupported_extensions: tuple[str, ...]
    references: dict[tuple[str, str], int]  # (path, name) -> other files mentioning it
    children: tuple[tuple[str, int], ...]  # (child directory, file count)
    imports_from: tuple[tuple[str, int], ...]  # (package, files importing it)
    imported_by: tuple[tuple[str, int], ...]  # (package, files importing this one)

    @property
    def cycles(self) -> tuple[str, ...]:
        imported_by = {package for package, _ in self.imported_by}
        return tuple(sorted(p for p, _ in self.imports_from if p in imported_by))


class Repository:
    """The git repository's tracked files, read once and shared by every map."""

    def __init__(self, root: Path):
        self.root = root
        listed = subprocess.run(
            ["git", "ls-files", "-z"], cwd=root, check=True, capture_output=True
        ).stdout.decode()
        self.tracked = [p for p in listed.split("\0") if p]
        self._texts: dict[str, str] = {}
        self._words: Optional[dict[str, frozenset[str]]] = None
        self._facts: dict[str, FileFacts] = {}

    def text(self, path: str) -> str:
        if path not in self._texts:
            try:
                self._texts[path] = (self.root / path).read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                self._texts[path] = ""
        return self._texts[path]

    def facts(self, path: str) -> Optional[FileFacts]:
        extractor = extractors.for_extension(_extension(path))
        if extractor is None:
            return None
        if path not in self._facts:
            self._facts[path] = extractor.extract(self.text(path))
        return self._facts[path]

    def files_mentioning(self, name: str, excluding: str) -> int:
        if self._words is None:
            self._words = {p: frozenset(_WORD.findall(self.text(p))) for p in self.tracked}
        return sum(1 for p, words in self._words.items() if p != excluding and name in words)


def build_map(repository: Repository, directory: str) -> DirectoryMap:
    directory = directory.rstrip("/")
    base = repository.root / directory
    paths = sorted(
        str(p.relative_to(repository.root))
        for p in base.iterdir()
        if p.is_file() and not p.name.startswith(".")
    )
    files = tuple(
        FileEntry(p, len(repository.text(p).splitlines()), repository.facts(p)) for p in paths
    )
    packages = tuple(sorted({f.facts.package for f in files if f.facts and f.facts.package}))
    unsupported = tuple(sorted({"." + _extension(f.path) for f in files if f.facts is None}))

    references: dict[tuple[str, str], int] = {}
    for entry in files:
        for declaration in _declarations(entry):
            names = [] if declaration.file_private else [declaration.name]
            names += [member.name for member in declaration.members]
            for name in names:
                references[(entry.path, name)] = repository.files_mentioning(name, entry.path)

    children = tuple(
        (str(p.relative_to(repository.root)), _count_files(p))
        for p in sorted(base.iterdir())
        if p.is_dir() and not p.name.startswith(".")
    )
    return DirectoryMap(
        directory=directory,
        packages=packages,
        files=files,
        unsupported_extensions=unsupported,
        references=references,
        children=children,
        imports_from=_imports_from(files, packages),
        imported_by=_imported_by(repository, directory, packages, files),
    )


def render(directory_map: DirectoryMap) -> str:
    m = directory_map
    out = [f"# {m.directory}", "", f"Package: {' '.join(m.packages)}"]
    if m.unsupported_extensions:
        out.append(
            f"No extractor for: {' '.join(m.unsupported_extensions)} — read those files to judge them."
        )
    out += [
        "",
        f"## Files ({len(m.files)})",
        "",
        "Each declaration is `kind name`, then the number of other files that mention its",
        "name. The count is a word match, so a common name over-counts. A declaration with",
        "no count is private to its file.",
        "",
        "- A count of 0: no other file mentions the declaration. It may be unused, or used",
        "  only in its own file. Check the file body before proposing removal or a narrower",
        "  visibility.",
        "- A count of 1 or more: another file mentions the declaration, usually because it",
        "  uses it. Do not propose making the declaration private because of this count.",
        "",
        "Indented under a class or object are its exposed members (not private, protected,",
        "or override), counted the same way.",
        "",
    ]
    for entry in m.files:
        out.append(f"- {entry.path} ({entry.lines} lines)")
        for declaration in _declarations(entry):
            if declaration.file_private:
                out.append(f"  - {declaration.kind} {declaration.name}")
            else:
                count = m.references[(entry.path, declaration.name)]
                out.append(f"  - {declaration.kind} {declaration.name} — {count}")
            for member in declaration.members:
                count = m.references[(entry.path, member.name)]
                out.append(f"    - {member.kind} {member.name} — {count}")
    out += ["", "## Child directories", ""]
    out += [f"- {path}/ ({count} files)" for path, count in m.children] or ["None."]
    if m.packages:
        out += ["", "## Imports from other packages (files importing)", ""]
        out += _counted(m.imports_from)
        out += ["", "## Imported by other packages (files importing)", ""]
        out += _counted(m.imported_by)
        out += ["", "## Both ways (a dependency cycle)", ""]
        out += [f"- {package}" for package in m.cycles] or ["None."]
    return "\n".join(out) + "\n"


def _declarations(entry: FileEntry) -> tuple[Declaration, ...]:
    return entry.facts.declarations if entry.facts else ()


def _imports_from(files: Iterable[FileEntry], own: tuple[str, ...]) -> tuple[tuple[str, int], ...]:
    counts: Counter[str] = Counter()
    for entry in files:
        if entry.facts:
            counts.update(set(entry.facts.imports) - set(own))
    return _sorted_counts(counts)


def _imported_by(
    repository: Repository, directory: str, own: tuple[str, ...], files: Iterable[FileEntry]
) -> tuple[tuple[str, int], ...]:
    extensions = {_extension(f.path) for f in files if f.facts}
    counts: Counter[str] = Counter()
    for path in repository.tracked:
        if _extension(path) not in extensions or path.startswith(directory + "/"):
            continue
        facts = repository.facts(path)
        if facts and facts.package not in own and set(facts.imports) & set(own):
            counts[facts.package or ""] += 1
    return _sorted_counts(counts)


def _sorted_counts(counts: Counter[str]) -> tuple[tuple[str, int], ...]:
    return tuple(sorted(counts.items(), key=lambda item: (-item[1], item[0])))


def _counted(items: tuple[tuple[str, int], ...]) -> list[str]:
    return [f"- {package} ({count})" for package, count in items] or ["None."]


def _count_files(directory: Path) -> int:
    return sum(1 for p in directory.rglob("*") if p.is_file() and not p.name.startswith("."))


def _extension(path: str) -> str:
    name = path.rsplit("/", 1)[-1]
    return name.rsplit(".", 1)[-1] if "." in name else ""
