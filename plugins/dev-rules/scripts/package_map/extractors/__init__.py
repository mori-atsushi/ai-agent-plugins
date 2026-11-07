"""Language extractors for the package map.

Each extractor module defines ``EXTENSIONS`` (file extensions without the dot) and
``extract(text) -> FileFacts``. To support a language, add a module here and list it
in ``_MODULES``.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from types import ModuleType
from typing import Optional


@dataclass(frozen=True)
class Member:
    """An exposed member of a top-level declaration."""

    kind: str
    name: str


@dataclass(frozen=True)
class Declaration:
    """A top-level declaration that code outside its file can use."""

    kind: str
    name: str
    members: tuple[Member, ...] = ()


@dataclass(frozen=True)
class FileFacts:
    """What an extractor reads from one file. ``imports`` are package names."""

    package: Optional[str] = None
    declarations: tuple[Declaration, ...] = ()
    imports: tuple[str, ...] = field(default_factory=tuple)


def _modules() -> list[ModuleType]:
    from . import kotlin

    return [kotlin]


def for_extension(extension: str) -> Optional[ModuleType]:
    """The extractor that reads files with ``extension``, or None."""
    for module in _modules():
        if extension in module.EXTENSIONS:
            return module
    return None
