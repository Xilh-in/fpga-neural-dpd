#!/usr/bin/env python3
"""Run reproducible offline validation from any current working directory."""
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main():
    failures = []
    skill = (ROOT / "skill.md").read_text(encoding="utf-8")
    if not re.match(r"\A---\nname: zynq-sdt-migration\ndescription: [^\n]+\n---\n", skill):
        failures.append("skill.md frontmatter")
    for path in sorted(ROOT.parent.rglob("*.md")):
        text = path.read_text(encoding="utf-8")
        if text.count("```") % 2:
            failures.append(f"unbalanced code fences: {path.name}")
        for link in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if "://" in link or link.startswith("#"):
                continue
            target = link.split("#", 1)[0]
            if target and not (path.parent / target).exists():
                failures.append(f"missing link: {path.relative_to(ROOT.parent)} -> {link}")
    if failures:
        for message in failures:
            print("FAIL:", message)
        return 1
    print("PASS: skill entry, Markdown fences, relative references", flush=True)
    tests = subprocess.run([sys.executable, "-B", "-m", "unittest", "discover",
                            "-s", str(ROOT / "tests"), "-v"], cwd=ROOT)
    if tests.returncode:
        return tests.returncode
    commands = [
        (["--config", "examples/spi_mapping_valid.json", "--bsp-header", "examples/example_bsp.h",
          "--no-os-spi-header", "examples/example_no_os_spi.h"], 0, "PASS", None),
        (["--config", "examples/spi_mapping_invalid.json"], 1, "FAIL", "BUS_ID_OUT_OF_RANGE"),
        (["--config", "examples/non_sdt_mapping_valid.json"], 0, "PASS", None),
        (["--config", "examples/does_not_exist.json"], 2, "INPUT_ERROR", None),
    ]
    for args, code, status, required in commands:
        run = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/check_spi_contract.py"), *args],
                             cwd=ROOT, text=True, capture_output=True)
        try:
            result = json.loads(run.stdout if run.stdout.strip() else run.stderr)
            assert run.returncode == code, (run.returncode, run.stdout, run.stderr)
            assert result["status"] == status, result
            if required:
                assert required in {issue["code"] for issue in result["issues"]}, result
        except (AssertionError, ValueError, KeyError) as exc:
            print("FAIL: CLI", args, exc)
            return 1
        print(f"PASS: CLI {Path(args[1]).name}, expected exit {code}")
    print("PASS: all offline checks; no board or Vitis invocation")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
