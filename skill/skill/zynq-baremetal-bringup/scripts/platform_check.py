"""Read-only Zynq project/profile consistency check; does not build or download anything."""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET


def check(profile, xpr, application):
    wanted = profile['part'].lower()
    if not wanted.startswith('xc7z') or profile['runtime'] != 'standalone' or profile['processor'] not in ('ps7_cortexa9_0','ps7_cortexa9_1'):
        raise ValueError('this adapter is for Zynq-7000 Cortex-A9 standalone, not Linux/PYNQ/UltraScale+')
    parts = {node.attrib['Val'].lower() for node in ET.parse(xpr).iter()
             if node.attrib.get('Name') == 'Part' and 'Val' in node.attrib}
    if len(parts) != 1:
        raise ValueError('XPR must declare exactly one Part; do not infer one from a tutorial title')
    actual_part = next(iter(parts))
    root = ET.parse(application).getroot()
    actual_cpu, actual_os = root.attrib.get('cpuInstance'), root.attrib.get('os')
    if actual_part != wanted:
        raise ValueError(f'part mismatch: expected {wanted}, found {actual_part}')
    if actual_cpu != profile['processor'] or actual_os != profile['runtime']:
        raise ValueError(f'processor/runtime mismatch: found {actual_cpu}/{actual_os}')
    return dict(status='PASS', board_profile=profile['board'], part=actual_part,
                processor=actual_cpu, runtime=actual_os,
                hardware_operations='NONE',
                scope='XML/profile consistency only; no proof of board identity, constraints, DDR, XSA/ELF pairing or build success')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile',type=Path,required=True)
    parser.add_argument('--xpr',type=Path,required=True)
    parser.add_argument('--application',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    try:
        report=check(json.loads(args.profile.read_text(encoding='utf-8')),args.xpr,args.application)
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(report,indent=2),encoding='utf-8')
        print(json.dumps(report))
    except (OSError,ValueError,KeyError,ET.ParseError) as error:
        print(f'PLATFORM CHECK FAILED: {error}')
        raise SystemExit(2)
