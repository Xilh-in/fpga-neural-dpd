"""Hash manifests, portable ZIPs and explicit-command smoke tests; Python stdlib only."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import subprocess
import tempfile
import zipfile

EXCLUDED = {'.venv','__pycache__','.git','_work'}
MANIFEST = 'handoff_manifest.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pack(source, output):
    source, output = Path(source).resolve(), Path(output).resolve()
    if not source.is_dir() or output.is_relative_to(source):
        raise ValueError('source must be a directory; output ZIP must be outside it')
    files = []
    for path in sorted(source.rglob('*')):
        if any(part in EXCLUDED for part in path.relative_to(source).parts):
            continue
        if path.is_symlink():
            raise ValueError(f'symlink not supported: {path}')
        if path.is_file() and path.name != MANIFEST:
            files.append(path)
    if not files:
        raise ValueError('cannot pack an empty source')
    manifest = {path.relative_to(source).as_posix(): digest(path) for path in files}
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.relative_to(source).as_posix())
        archive.writestr(MANIFEST, json.dumps(manifest, indent=2))
    return dict(files=len(files), archive_sha256=digest(output))


def verify(root):
    root = Path(root).resolve()
    manifest = json.loads((root / MANIFEST).read_text(encoding='utf-8'))
    for name, expected in manifest.items():
        original = root / name
        path = original.resolve()
        if not path.is_relative_to(root) or original.is_symlink() or digest(path) != expected:
            raise ValueError(f'missing/changed/escaping file: {name}')
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*')
              if p.is_file() and p.name != MANIFEST and not any(k in EXCLUDED for k in p.relative_to(root).parts)}
    if actual != set(manifest):
        raise ValueError('unexpected/missing files outside manifest')
    return dict(status='PASS', files=len(manifest))


def smoke(archive_path, command, timeout=60):
    archive_path = Path(archive_path).resolve()
    if not command:
        raise ValueError('provide an explicit command after --; archive never supplies executable instructions')
    with tempfile.TemporaryDirectory(prefix='handoff_check_') as tmp:
        root = Path(tmp) / 'unpacked'; root.mkdir()
        with zipfile.ZipFile(archive_path) as archive:
            for info in archive.infolist():
                name = info.filename.replace('\\','/')
                relative = PurePosixPath(name)
                mode = info.external_attr >> 16
                if relative.is_absolute() or '..' in relative.parts or ':' in name or stat.S_ISLNK(mode):
                    raise ValueError(f'unsafe ZIP member: {name}')
            archive.extractall(root)
        checked = verify(root)
        # A new cwd/PYTHONPATH prevents routine accidental imports from the source checkout.
        env = os.environ.copy(); env.pop('PYTHONPATH', None)
        result = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True,
                                encoding='utf-8', errors='replace', timeout=timeout)
        return dict(manifest=checked, exit_code=result.returncode, stdout=result.stdout, stderr=result.stderr,
                    note='Fresh extraction/cwd only; not an OS sandbox and not proof of zero absolute dependencies')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='mode', required=True)
    p = sub.add_parser('pack'); p.add_argument('source', type=Path); p.add_argument('output', type=Path)
    p = sub.add_parser('verify'); p.add_argument('root', type=Path)
    p = sub.add_parser('smoke'); p.add_argument('archive', type=Path); p.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        if args.mode == 'pack': report = pack(args.source, args.output)
        elif args.mode == 'verify': report = verify(args.root)
        else:
            command = args.command[1:] if args.command[:1] == ['--'] else args.command
            report = smoke(args.archive, command)
        print(json.dumps(report, indent=2))
        raise SystemExit(1 if report.get('exit_code', 0) else 0)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f'CHECK FAILED: {error}')
        raise SystemExit(2)
