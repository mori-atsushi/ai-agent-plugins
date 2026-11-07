"""Kotlin extractor.

Reads the package, imports, top-level declarations, and each top-level class's
exposed members: a fun, val, or var directly in its body, constructor properties
included, that is not private, protected, or an override. Members are found by
Kotlin's standard four-space indentation.
"""

from __future__ import annotations

import re
from typing import Optional

from . import Declaration, FileFacts, Member

EXTENSIONS = ("kt", "kts")

_ANNOTATION = re.compile(r"@[A-Za-z.]+(\([^)]*\))?\s*")
_TOP_LEVEL_KEYWORD = re.compile(r"(?:^|\s)(class|interface|object|fun|val|var|typealias)\s")
_MEMBER_KEYWORD = re.compile(r"(?:^|\s)(fun|val|var)\s")
_MEMBER_MODIFIERS = re.compile(
    r"^((public|internal|open|abstract|final|const|lateinit|inline|suspend|operator"
    r"|infix|tailrec|external)\s+)*(fun|val|var)$"
)
# An optional receiver with type arguments, then the declared name.
_NAME = re.compile(r"^[A-Za-z_]\w*(<[^>]*>)?\??(\.[A-Za-z_]\w*)*")
_TYPE_PARAMETERS = re.compile(r"^<[^>]*>\s*")
# A constructor property written on the class's own line: modifiers, then val or var.
_INLINE_PROPERTY = re.compile(r"(?:\(|,)\s*((?:\w+\s+)*?)(val|var)\s+(\w+)")


def extract(text: str) -> FileFacts:
    package: Optional[str] = None
    imports: list[str] = []
    declarations: list[Declaration] = []
    owner: Optional[Declaration] = None
    members: list[Member] = []

    def close_owner() -> None:
        nonlocal owner, members
        if owner is not None:
            declarations[-1] = Declaration(
                owner.kind, owner.name, owner.file_private, tuple(members)
            )
        owner, members = None, []

    for line in text.splitlines():
        if line.startswith("package "):
            package = line.split()[1].rstrip(";")
        elif line.startswith("import "):
            imports.append(_imported_package(line.split()[1].rstrip(";")))
        elif line[:1].isalpha() and line[:1].islower() or line.startswith("@"):
            close_owner()
            declaration = _declaration(line)
            if declaration is None:
                continue
            declarations.append(declaration)
            if declaration.kind.endswith(("class", "interface", "object")) and not declaration.file_private:
                owner = declaration
                members = _inline_properties(line)
        elif owner is not None and line.startswith("    ") and not line[4:5].isspace():
            member = _member(line[4:])
            if member is not None:
                members.append(member)
    close_owner()
    return FileFacts(package, tuple(declarations), tuple(imports))


def _imported_package(target: str) -> str:
    """The package of an import: segments before the first capitalized one, or all
    but the last (a top-level function, property, or ``*``)."""
    parts = target.split(".")
    package: list[str] = []
    for part in parts[:-1]:
        if part[:1].isupper():
            break
        package.append(part)
    return ".".join(package)


def _split(line: str, keyword: re.Pattern) -> Optional[tuple[str, str]]:
    """The kind (modifiers and keyword) and the declared name, or None."""
    line = _ANNOTATION.sub("", line)
    match = keyword.search(line)
    if match is None:
        return None
    kind = line[: match.end(1)].strip()
    rest = line[match.end():]
    if kind.endswith("fun") and rest.startswith("interface "):
        kind += " interface"
        rest = rest[len("interface "):].lstrip()
    rest = _TYPE_PARAMETERS.sub("", rest)
    name = _NAME.match(rest)
    if name is None:
        return None
    return kind, re.sub(r"<[^>]*>", "", name.group(0)).split(".")[-1]


def _declaration(line: str) -> Optional[Declaration]:
    split = _split(line, _TOP_LEVEL_KEYWORD)
    if split is None:
        return None
    kind, name = split
    return Declaration(kind, name, file_private="private" in kind.split())


def _inline_properties(line: str) -> list[Member]:
    """Constructor properties declared on the class's own line, as in
    ``data class Point(val x: Int, private val y: Int)``."""
    members = []
    for modifiers, keyword, name in _INLINE_PROPERTY.findall(_ANNOTATION.sub("", line)):
        kind = (modifiers + keyword).strip()
        if _MEMBER_MODIFIERS.match(kind):
            members.append(Member(kind, name))
    return members


def _member(line: str) -> Optional[Member]:
    split = _split(line, _MEMBER_KEYWORD)
    if split is None or not _MEMBER_MODIFIERS.match(split[0]):
        return None
    return Member(*split)
