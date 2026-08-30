#!/usr/bin/env python3
"""Derive and verify the public distribution's embedded trust identities."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKSUM_FILES = (
    "install.sh",
    "install-lifecycle.sh",
    "repair-ravyr.sh",
    "veleis",
    "veleis-postgres-memory.sh",
    "release.json",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def replace_constant(path: Path, name: str, expected: str, write: bool) -> None:
    content = path.read_text(encoding="utf-8")
    pattern = rf'(?m)^readonly {re.escape(name)}="[0-9a-f]{{64}}"$'
    matches = re.findall(pattern, content)
    if len(matches) != 1:
        raise SystemExit(f"{path.name}: expected exactly one {name} checksum constant")
    replacement = f'readonly {name}="{expected}"'
    if matches[0] == replacement:
        return
    if not write:
        raise SystemExit(f"{path.name}: {name} does not match the final distribution identity")
    path.write_text(re.sub(pattern, replacement, content), encoding="utf-8")


def expected_sums() -> str:
    return "".join(f"{sha256(ROOT / name)}  {name}\n" for name in CHECKSUM_FILES)


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    args = parser.parse_args()

    metadata_path = ROOT / "release.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    if metadata.get("product") != "Veleis":
        raise SystemExit("release.json: product must be Veleis")

    identities = {
        "metadata": sha256(metadata_path),
        "lifecycle": sha256(ROOT / "veleis"),
        "postgres_memory": sha256(ROOT / "veleis-postgres-memory.sh"),
        "compose": sha256(ROOT / "deploy/compose.yaml"),
    }
    if metadata.get("lifecycle_tool_sha256") != identities["lifecycle"]:
        raise SystemExit("release.json: lifecycle_tool_sha256 does not match veleis")

    replace_constant(ROOT / "install.sh", "RELEASE_METADATA_SHA256", identities["metadata"], args.write)
    replace_constant(ROOT / "install.sh", "LIFECYCLE_SHA256", identities["lifecycle"], args.write)
    replace_constant(ROOT / "install.sh", "POSTGRES_MEMORY_SHA256", identities["postgres_memory"], args.write)
    replace_constant(ROOT / "install-lifecycle.sh", "RELEASE_SHA256", identities["metadata"], args.write)
    replace_constant(ROOT / "install-lifecycle.sh", "TOOL_SHA256", identities["lifecycle"], args.write)
    replace_constant(ROOT / "install-lifecycle.sh", "POSTGRES_MEMORY_SHA256", identities["postgres_memory"], args.write)
    replace_constant(ROOT / "install-lifecycle.sh", "COMPOSE_SHA256", identities["compose"], args.write)

    sums_path = ROOT / "SHA256SUMS"
    sums = expected_sums()
    if args.write:
        sums_path.write_text(sums, encoding="utf-8")
    elif sums_path.read_text(encoding="utf-8") != sums:
        raise SystemExit("SHA256SUMS does not match the final distribution files")

    print(f"release metadata SHA-256: {identities['metadata']}")
    print("public release integrity: PASS")


if __name__ == "__main__":
    main()
