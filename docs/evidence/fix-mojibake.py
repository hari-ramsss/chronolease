#!/usr/bin/env python3
"""Detect/repair UTF-8 bytes that were decoded as Windows-1252 (mojibake).

Usage: python3 fix-mojibake.py scan|fix [path ...]
Only text-bearing source/documentation files are considered. Binary artifacts,
git internals, build outputs and vendored libraries are skipped. The repair is
iterative because several files are double- or triple-encoded.
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXTENSIONS = {".md", ".txt", ".rs", ".sol", ".ts", ".js", ".toml", ".json", ".sh", ".ps1", ".py", ".log", ".wat", ".b64"}
SKIP_DIRS = {".git", "target", "out", "cache", "forge-std", "node_modules"}
CLASS = "[\u0080-\u00ff\u0192\u02c6\u02dc\u0160\u0161\u0152\u0153\u017d\u017e\u0178\u2000-\u206f\u20ac\u2122]+"
RUN = re.compile(CLASS)
MARKERS = {chr(code) for code in (0xC3, 0xE2, 0xC2, 0x192, 0xC6)}
BAD_AFTER = MARKERS | {"\x9d", "\x9c", "\x9f"}


def to_bytes(s):
    out = bytearray()
    for ch in s:
        o = ord(ch)
        if o < 0x80 or 0x80 <= o <= 0x9F:
            out.append(o)
        else:
            try:
                out.extend(ch.encode("cp1252"))
            except UnicodeEncodeError:
                return None
    return bytes(out)


def undo_once(s):
    raw = to_bytes(s)
    if raw is None:
        return None
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return None


def undo_fully(s):
    current = s
    for _ in range(4):
        nxt = undo_once(current)
        if nxt is None or nxt == current:
            break
        current = nxt
    return current


def repair(text):
    changes = []
    out = []
    pos = 0
    for match in RUN.finditer(text):
        out.append(text[pos:match.start()])
        run = match.group()
        pos = match.end()
        i = 0
        while i < len(run):
            replaced = False
            for j in range(len(run), i + 1, -1):
                piece = run[i:j]
                if not any(c in MARKERS for c in piece):
                    continue
                fixed = undo_fully(piece)
                if fixed == piece or not fixed.strip():
                    continue
                if any(c in BAD_AFTER for c in fixed):
                    continue
                if not all(ord(c) >= 32 or c in "\t\r\n" for c in fixed):
                    continue
                out.append(fixed)
                changes.append((piece, fixed))
                i = j
                replaced = True
                break
            if not replaced:
                out.append(run[i])
                i += 1
    out.append(text[pos:])
    return "".join(out), changes


def files():
    for base, dirs, names in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in names:
            path = os.path.join(base, name)
            if os.path.basename(path) == "fix-mojibake.py":
                continue
            if os.path.splitext(name)[1].lower() in EXTENSIONS:
                yield path


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "scan"
    targets = sys.argv[2:] or list(files())
    total = 0
    for path in targets:
        if os.path.basename(path) == "fix-mojibake.py":
            continue
        with open(path, "rb") as handle:
            raw = handle.read()
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        fixed, changes = repair(text)
        if changes:
            total += len(changes)
            print(f"{os.path.relpath(path, ROOT)}: {len(changes)} sequence(s)")
            if mode == "fix":
                with open(path, "w", encoding="utf-8", newline="") as handle:
                    handle.write(fixed)
    print(f"TOTAL: {total} sequence(s) in {len(targets)} file(s)")


if __name__ == "__main__":
    main()
