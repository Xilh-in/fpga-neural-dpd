"""Offline skill verification. Optional DPD replay needs NumPy; no hardware is accessed."""
import argparse
from datetime import datetime,timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE=Path(__file__).resolve().parent


def check(command,name,records,environment=None):
    try:
        r=subprocess.run([str(x) for x in command],cwd=HERE,capture_output=True,text=True,
                         encoding='utf-8',errors='replace',timeout=90,env=environment)
        records[name]=dict(status='PASS' if r.returncode==0 else 'FAIL',exit_code=r.returncode,
                           stdout=r.stdout,stderr=r.stderr)
        print(name+': '+records[name]['status'])
        if r.returncode:print(r.stdout+r.stderr)
        return r.returncode==0
    except (OSError,subprocess.TimeoutExpired) as error:
        records[name]=dict(status='FAIL',error=str(error));print(name+': FAIL');return False


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--include-dpd',action='store_true')
    parser.add_argument('--include-pynq',action='store_true',help='explicitly enable optional extension; not the current board runtime')
    parser.add_argument('--output',type=Path,default=HERE/'out/validation_results.json')
    args=parser.parse_args()
    records={}
    skills=sorted(p for p in HERE.iterdir() if p.is_dir() and (p/'skill.md').is_file())
    if args.include_pynq:
        optional=HERE/'extensions/pynq-overlay-contract'
        if not (optional/'skill.md').is_file():parser.error('PYNQ extension is not included in this core package')
        skills.append(optional)
    for path in skills:
        text=(path/'skill.md').read_text(encoding='utf-8')
        match=re.match(r'---\n(.*?)\n---\n',text,re.S)
        good=bool(match and re.search(r'^name: '+re.escape(path.name)+r'$',match[1],re.M)
                  and re.search(r'^description: .+',match[1],re.M) and (path/'readme.md').is_file())
        records['skill_'+path.name]=dict(status='PASS' if good else 'FAIL')
    success=bool(skills) and all(r['status']=='PASS' for r in records.values())
    test_environment=os.environ.copy();test_environment['SKILL_INCLUDE_PYNQ']='1' if args.include_pynq else '0'
    success &= check([sys.executable,'-X','utf8','-m','unittest','discover','-s','tests','-v'],'unit_tests',records,test_environment)
    with tempfile.TemporaryDirectory(prefix='skill_replay_') as temp:
        temp=Path(temp)
        success &= check([sys.executable,'fpga-golden-check/scripts/golden_check.py','--capture','fpga-golden-check/assets/capture.csv',
                          '--reference','fpga-golden-check/assets/reference.csv','--contract','fpga-golden-check/assets/contract.json',
                          '--output',temp/'golden.json'],'golden_cli',records)
        success &= check([sys.executable,'fpga-bounded-io/scripts/mock_demo.py'],'bounded_cli',records)
        success &= check([sys.executable,'zynq-baremetal-bringup/scripts/platform_check.py','--profile','zynq-baremetal-bringup/assets/rk7100_profile.json',
                          '--xpr','zynq-baremetal-bringup/assets/mock_xpr.xml','--application','zynq-baremetal-bringup/assets/mock_app.xml',
                          '--output',temp/'platform.json'],'zynq_platform_cli',records)
        if args.include_pynq:
            for profile in ('a','b'):
                success &= check([sys.executable,'extensions/pynq-overlay-contract/scripts/overlay_contract.py','--contract',f'extensions/pynq-overlay-contract/assets/contract_{profile}.json',
                                  '--ip-dict',f'extensions/pynq-overlay-contract/assets/metadata_{profile}.json','--output',temp/f'pynq_{profile}.json'],
                                 'pynq_cli_'+profile,records)
        else:records['pynq_extension']=dict(status='SKIPPED',reason='Current RK7100 project is standalone, not PYNQ')
        if args.include_dpd:
            success &= check([sys.executable,'fpga-golden-check/cases/dpd/replay_case.py','--output',temp/'dpd'],'dpd_replay',records)
        else:
            records['dpd_replay']=dict(status='SKIPPED',reason='Use --include-dpd after installing requirements-dpd.txt')
    records['pynq_hardware']=dict(status='NOT_RUN',reason='No PYNQ board validation performed')
    records['vitis_2025_2_build']=dict(status='NOT_RUN',reason='Source/metadata skill tests do not build firmware')
    report=dict(timestamp_utc=datetime.now(timezone.utc).isoformat(),python=sys.version,checks=records,success=bool(success))
    args.output=args.output.resolve();args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
    print('SKILL_CHECKS_'+('PASS' if success else 'FAIL'))
    return 0 if success else 1


if __name__=='__main__':raise SystemExit(main())
