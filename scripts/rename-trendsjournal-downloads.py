#!/usr/bin/env python3
"""
Rename files from: tj-DD-mon_YYYY_XXXXXXXX[-N].pdf
           to:    YYYY-MM-DD_TrendsJournal[-N].pdf
"""

import re, os, sys
from pathlib import Path

MONTH_MAP = {
    "jan":"01","feb":"02","mar":"03","apr":"04",
    "may":"05","jun":"06","jul":"07","aug":"08",
    "sep":"09","oct":"10","nov":"11","dec":"12",
}
PREFIX_MAP = {"tj": "TrendsJournal"}

PATTERN = re.compile(
    r'^(?P<prefix>[a-z]+)'
    r'-(?P<day>\d{2})'
    r'-(?P<month>[a-z]{3})'
    r'_(?P<year>\d{4})'
    r'_[A-Za-z0-9]+'
    r'(?P<suffix>-\d+)?'
    r'\.pdf$',
    re.IGNORECASE
)

def build_new_name(match):
    prefix = match.group("prefix").lower()
    day    = match.group("day")
    month  = MONTH_MAP.get(match.group("month").lower())
    year   = match.group("year")
    suffix = match.group("suffix") or ""
    if month is None: return None
    label  = PREFIX_MAP.get(prefix)
    if label is None: return None
    return f"{year}-{month}-{day}_{label}{suffix}.pdf"

def rename_files(directory, dry_run=True):
    directory = Path(directory)
    files = sorted(directory.glob("*.pdf"))
    matches, skipped, conflicts = [], [], []

    for f in files:
        m = PATTERN.match(f.name)
        if not m:
            skipped.append(f.name); continue
        new_name = build_new_name(m)
        if new_name is None:
            skipped.append(f.name); continue
        new_path = directory / new_name
        if new_path.exists() and new_path != f:
            conflicts.append((f.name, new_name))
        else:
            matches.append((f, new_path))

    print(f"\n{'DRY RUN — ' if dry_run else ''}Renaming in: {directory}\n")
    print(f"{'OLD NAME':<50} → NEW NAME")
    print("-" * 85)
    for old, new in matches:
        print(f"{old.name:<50} → {new.name}")
        if not dry_run:
            old.rename(new)

    if conflicts:
        print("\n⚠ CONFLICTS (skipped):")
        for old, new in conflicts:
            print(f"  {old}  →  {new}")
    if skipped:
        print(f"\nSkipped (no match): {len(skipped)} file(s)")
        for s in skipped[:5]: print(f"  {s}")
        if len(skipped) > 5: print(f"  … and {len(skipped)-5} more")

    print(f"\nTotal renamed: {len(matches)}  |  Conflicts: {len(conflicts)}  |  Skipped: {len(skipped)}")

if __name__ == "__main__":
    directory = sys.argv[1] if len(sys.argv) > 1 else "."
    dry = "--execute" not in sys.argv
    rename_files(directory, dry_run=dry)
    if dry:
        print("\nRe-run with --execute to apply changes.")
