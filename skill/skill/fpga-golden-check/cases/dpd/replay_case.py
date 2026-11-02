"""Recompute the DPD case, then pass it through the generic golden comparator."""
import argparse
import csv
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def replay(output):
    import numpy as np
    from reference_model import load_parameters, fixed_reference
    output = Path(output); output.mkdir(parents=True, exist_ok=True)
    parameters = load_parameters(HERE / 'input/parameters.json')
    x = np.loadtxt(HERE / 'input/delay.csv', delimiter=',', skiprows=1, dtype=np.int64)
    observed = np.loadtxt(HERE / 'input/capture.csv', delimiter=',', skiprows=1, dtype=np.int64)
    final = np.loadtxt(HERE / 'input/final.csv', delimiter=',', skiprows=1, dtype=np.int64)
    if x.shape != (1024, 2) or observed.shape != x.shape or final.shape != x.shape:
        raise ValueError('this regression fixture requires three 1024x2 arrays')
    result = fixed_reference(x, parameters)
    reference_path = output / 'reference.csv'
    with reference_path.open('w', encoding='utf-8', newline='') as handle:
        writer = csv.writer(handle); writer.writerow(['I','Q','pre_i','pre_q'])
        for i in range(len(x)):
            writer.writerow([int(result['output'][i,0]), int(result['output'][i,1]),
                             float(result['accumulator'][i,0]/4096), float(result['accumulator'][i,1]/4096)])
    path = HERE.parents[1] / 'scripts/golden_check.py'
    spec = importlib.util.spec_from_file_location('case_golden_check', path)
    golden = importlib.util.module_from_spec(spec); spec.loader.exec_module(golden)
    report = golden.run(HERE/'input/capture.csv', reference_path, HERE/'contract.json', output/'golden_report.json')
    layer2 = result['l2_long'][24:1000]
    intermediate = int(np.sum((layer2 < -(1<<24)) | (layer2 >= (1<<24))))
    identity = bool(np.array_equal(x-observed, final))
    report.update(case='dpd_1026', hardware_origin='partner-provided capture; replay performs no board access',
                  intermediate_l2_saturations=intermediate, final_identity_matches=identity)
    assert report['status']=='PASS' and report['exact_scalar_matches']==1952
    assert len(report['rail_hits'])==16 and report['all_rail_hits_proven_overflow'] is True
    assert intermediate==58 and identity
    (output/'case_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(dict(status=report['status'], samples=report['sample_count'],
                         exact_scalars=report['exact_scalar_matches'], proven_saturations=16,
                         l2_saturations=intermediate)))
    return report


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    replay(parser.parse_args().output)
