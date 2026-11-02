"""Check submitted filenames, binary hashes and PL source-list paths without hardware access."""
from pathlib import Path
import re,hashlib,json,ast
root=Path(__file__).resolve().parents[1];errors=[];count=0
for p in root.rglob('*'):
 if '__pycache__' in p.parts: continue
 if not re.fullmatch(r'[a-z0-9_.-]+',p.name):errors.append('invalid name: '+str(p.relative_to(root)))
 if p.suffix=='.py':ast.parse(p.read_text(encoding='utf-8'),filename=str(p))
 if p.is_file():count+=1
for rel,sha in json.loads((root/'build/reports/unchanged_binaries.json').read_text()).items():
 if hashlib.sha256((root/rel).read_bytes()).hexdigest()!=sha:errors.append('binary mismatch: '+rel)
for rel in re.findall(r'(?:rtl|legacy)/[^\s{}]+',(root/'src/pl/inputs.tcl').read_text()):
 if not (root/'src/pl'/rel).is_file():errors.append('missing PL input: '+rel)
print(json.dumps({'files':count,'errors':errors,'status':'FAIL' if errors else 'PASS'},indent=2))
raise SystemExit(bool(errors))
