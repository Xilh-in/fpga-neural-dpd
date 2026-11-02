"""Compare multichannel CSV captures with a golden reference under an explicit contract."""
import argparse
import csv
import json
import math
from pathlib import Path


def load_csv(path, columns):
    with Path(path).open(encoding='utf-8-sig', newline='') as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames or not set(columns) <= set(reader.fieldnames):
            raise ValueError(f'{path}: missing columns {columns}')
        rows = []
        for number, row in enumerate(reader, 2):
            values = [float(row[name]) for name in columns]
            if not all(math.isfinite(value) for value in values):
                raise ValueError(f'{path}:{number}: nonfinite value')
            rows.append(values)
    if not rows:
        raise ValueError(f'{path}: empty capture')
    return rows


def compare(capture, reference, contract, preclip=None):
    channels = len(contract['capture_columns'])
    if channels == 0 or channels != len(contract['reference_columns']):
        raise ValueError('channel lists must have equal positive lengths')
    bits = contract.get('bits', 16)
    if type(bits) is not int or not 2 <= bits <= 53:
        raise ValueError('bits must be 2..53 for exact binary64 integer representation')
    if type(contract.get('signed', True)) is not bool:
        raise ValueError('signed must be a JSON boolean')
    if contract.get('signed', True) is not True:
        lower, upper = 0, (1 << bits) - 1
    else:
        lower, upper = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    offset = contract.get('offset', 0)
    start = contract.get('start', 0)
    stop = contract.get('stop', len(capture))
    if any(type(value) is not int for value in (start, stop, offset)):
        raise ValueError('start/stop/offset must be integers')
    if not 0 <= start < stop <= len(capture) or start + offset < 0 or stop + offset > len(reference):
        raise ValueError('declared comparison interval exceeds available capture/reference')
    tolerance = contract.get('absolute_tolerance', 0)
    if not isinstance(tolerance, (int, float)) or not math.isfinite(tolerance) or tolerance < 0:
        raise ValueError('absolute_tolerance must be finite and nonnegative')
    if preclip is not None and len(preclip) != len(reference):
        raise ValueError('preclip reference length differs')
    if any(len(row) != channels for row in capture + reference):
        raise ValueError('inconsistent channel count')
    mismatches, rail_hits, saturated = [], [], []
    max_error, square_error, exact = 0.0, 0.0, 0
    for index in range(start, stop):
        expected_index = index + offset
        for channel in range(channels):
            observed, expected = capture[index][channel], reference[expected_index][channel]
            if not math.isfinite(observed) or not math.isfinite(expected):
                raise ValueError('nonfinite numeric comparison value')
            if not lower <= observed <= upper:
                raise ValueError(f'capture[{index},{channel}] outside declared encoded range')
            error = observed - expected
            exact += error == 0
            max_error = max(max_error, abs(error))
            square_error += error * error
            if abs(error) > tolerance:
                mismatches.append(dict(index=index, channel=channel, observed=observed, expected=expected))
            if observed in (lower, upper):
                rail_hits.append(dict(index=index, channel=channel, value=observed))
            # Raw values must already be in OUTPUT INTEGER units; upper+1 is the overflow threshold.
            if preclip is not None:
                raw = preclip[expected_index][channel]
                if not math.isfinite(raw):
                    raise ValueError('nonfinite preclip value')
                if raw < lower or raw >= upper + 1:
                    saturated.append(dict(index=index, channel=channel, before_clip=raw,
                                          expected_rail=lower if raw < lower else upper))
    count = (stop - start) * channels
    rail_positions = {(row['index'], row['channel'], row['value']) for row in rail_hits}
    predicted_positions = {(row['index'], row['channel'], row['expected_rail']) for row in saturated}
    return dict(status='PASS' if not mismatches else 'FAIL', sample_count=stop - start,
                scalar_count=count, exact_scalar_matches=exact, offset=offset, start=start, stop=stop,
                maximum_absolute_error=max_error, rmse=math.sqrt(square_error / count),
                mismatch_count=len(mismatches), mismatches=mismatches[:100], rail_hits=rail_hits,
                predicted_saturation=saturated if preclip is not None else None,
                all_rail_hits_proven_overflow=(rail_positions == predicted_positions) if preclip is not None else None,
                note='Rail hits alone do not prove internal overflow. Bounds/start/stop are supplied, not inferred.')


def run(capture_path, reference_path, contract_path, output):
    contract = json.loads(Path(contract_path).read_text(encoding='utf-8'))
    capture = load_csv(capture_path, contract['capture_columns'])
    reference = load_csv(reference_path, contract['reference_columns'])
    preclip = load_csv(reference_path, contract['preclip_columns']) if contract.get('preclip_columns') else None
    report = compare(capture, reference, contract, preclip)
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    Path(output).write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', type=Path, required=True)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--contract', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        result = run(args.capture, args.reference, args.contract, args.output)
        print(json.dumps({key: result[key] for key in ('status','sample_count','scalar_count','offset','maximum_absolute_error','mismatch_count')}))
        raise SystemExit(0 if result['status'] == 'PASS' else 1)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f'INVALID INPUT: {error}')
        raise SystemExit(2)
