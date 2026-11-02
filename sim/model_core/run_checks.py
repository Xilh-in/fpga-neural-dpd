"""Reproduce the clipping audit using only files inside this analysis directory."""
import csv
import hashlib
import json
from pathlib import Path
import numpy as np
from reference_model import load_parameters, fixed_reference, float_reference, delayed_taps

HERE = Path(__file__).resolve().parent


def write_csv(path, fields, rows):
    with path.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def main():
    p = load_parameters(HERE / 'input/model_0216_0.json')
    arrays = {name: np.loadtxt(HERE / f'input/{name}_1024.csv', delimiter=',', skiprows=1, dtype=np.int64)
              for name in ('tx_delay', 'model_out', 'tx_final')}
    if any(a.shape != (1024, 2) for a in arrays.values()):
        raise ValueError('Expected three 1024 x 2 CSV arrays')
    x, measured, final = (arrays[key] for key in ('tx_delay', 'model_out', 'tx_final'))
    fixed, ideal = fixed_reference(x, p), float_reference(x, p)
    np.savez_compressed(HERE / 'fixed_reference.npz', **fixed)
    np.savez_compressed(HERE / 'float_reference.npz', **ideal)
    # L1 centred dilated window: +/-20 samples; NL shifted inputs: another +/-4.
    # model_out[n] corresponds to a reference centred at tx_delay[n+1].
    offset = 1
    indices = np.arange(23, 999)
    reference_indices = indices + offset
    errors = fixed['output'][reference_indices] - measured[indices]
    expected_clips = np.any((fixed['accumulator'][reference_indices] < -(1 << 27)) |
                            (fixed['accumulator'][reference_indices] >= (1 << 27)), axis=1)
    observed_clips = np.any(np.isin(measured[indices], [-32768, 32767]), axis=1)
    clips = np.where(np.any(np.isin(measured, [-32768, 32767]), axis=1))[0]
    assert np.array_equal(errors, np.zeros_like(errors)), 'reference differs from captured valid window'
    assert np.array_equal(expected_clips, observed_clips), 'clip positions differ'
    assert len(clips) == 16 and np.all(measured[clips, 1] == -32768)
    assert np.array_equal(x - measured, final), 'three CSVs fail pointwise subtraction'

    l1_saturation = (fixed['l1_long'][reference_indices] < -(1 << 30)) | (fixed['l1_long'][reference_indices] >= (1 << 30))
    l2_saturation = (fixed['l2_long'][reference_indices] < -(1 << 24)) | (fixed['l2_long'][reference_indices] >= (1 << 24))
    l3_saturation = (fixed['accumulator'][reference_indices] < -(1 << 27)) | (fixed['accumulator'][reference_indices] >= (1 << 27))
    wide_l2 = fixed['l2_long'] >> 9
    wide_i = wide_l2[:, :, 0] @ p['w3i'] - wide_l2[:, :, 1] @ p['w3q'] + (p['b3i'] << 14)
    wide_q = wide_l2[:, :, 0] @ p['w3q'] + wide_l2[:, :, 1] @ p['w3i'] + (p['b3q'] << 14)
    wide_output = np.stack((wide_i, wide_q), axis=-1) / 4096
    ideal_clipped = np.clip(np.floor(ideal['output'][reference_indices]), -32768, 32767)
    summary = dict(
        comparable_capture_indices_zero_based=[23, 998], comparable_sample_count=len(indices),
        comparable_scalar_count=errors.size, reference_input_centre_offset=offset,
        exact_scalar_matches=int(np.sum(errors == 0)), maximum_absolute_error_lsb=int(np.abs(errors).max()),
        clipping_indices_zero_based=clips.tolist(), clipping_csv_lines_including_header=(clips + 2).tolist(),
        predicted_clipping_matches=True, all_clips_q_negative=True,
        pointwise_final_equals_delayed_input_minus_model=True,
        l1_saturation_scalar_count=int(l1_saturation.sum()),
        l2_saturation_scalar_count=int(l2_saturation.sum()),
        l2_saturation_by_channel_i_q=l2_saturation.sum(axis=0).tolist(),
        l3_saturation_by_i_q=l3_saturation.sum(axis=0).tolist(),
        l3_before_output_clip_min_i_q=(fixed['accumulator'][reference_indices].min(axis=0) / 4096).tolist(),
        l3_before_output_clip_max_i_q=(fixed['accumulator'][reference_indices].max(axis=0) / 4096).tolist(),
        ideal_float_final_clip_count_i_q=np.sum((ideal['output'][reference_indices] < -32768) |
                                               (ideal['output'][reference_indices] >= 32768), axis=0).tolist(),
        ideal_float_clipped_vs_measured_rmse_lsb=float(np.sqrt(np.mean((ideal_clipped - measured[indices])**2))),
        fixed_without_l2_clip_vs_ideal_float_rmse_lsb=float(np.sqrt(np.mean((wide_output[reference_indices] - ideal['output'][reference_indices])**2))),
        input_hashes={path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted((HERE / 'input').glob('*')) if path.is_file()},
        rtl_simulation_status='NOT EXECUTED (rtl_trace.csv absent)' if not (HERE / 'simulation/rtl_trace.csv').exists() else
                              'Trace present; run check_rtl_trace.py to validate; see rtl_validation.json',
        limits='Capture history/future outside rows 0..1023 are unavailable. Only measured rows 23..998 are asserted.')
    (HERE / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')

    clip_rows = []
    for index in clips:
        centre = index + offset
        clip_rows.append(dict(capture_index_zero_based=int(index), sample_number_one_based=int(index + 1),
                              csv_line_including_header=int(index + 2), input_centre_index=int(centre),
                              measured_i=int(measured[index, 0]), measured_q=int(measured[index, 1]),
                              python_fixed_i=int(fixed['output'][centre, 0]), python_fixed_q=int(fixed['output'][centre, 1]),
                              q_before_output_clipping=float(fixed['accumulator'][centre, 1] / 4096),
                              q_accumulator_integer=int(fixed['accumulator'][centre, 1]),
                              q_accumulator_lower_limit=-(1 << 27), ideal_float_q=float(ideal['output'][centre, 1]),
                              agrees=True))
    write_csv(HERE / 'clipping_points.csv', list(clip_rows[0]), clip_rows)

    rows = []
    for index in range(1024):
        valid = 23 <= index <= 998
        centre = index + 1
        row = dict(capture_index_zero_based=index, verified=valid,
                   measured_i=int(measured[index, 0]), measured_q=int(measured[index, 1]),
                   python_i=int(fixed['output'][centre, 0]) if valid else '',
                   python_q=int(fixed['output'][centre, 1]) if valid else '',
                   error_i=int(fixed['output'][centre, 0] - measured[index, 0]) if valid else '',
                   error_q=int(fixed['output'][centre, 1] - measured[index, 1]) if valid else '',
                   q_before_clip=float(fixed['accumulator'][centre, 1] / 4096) if valid else '',
                   ideal_float_q=float(ideal['output'][centre, 1]) if valid else '')
        rows.append(row)
    write_csv(HERE / 'comparison_all_samples.csv', list(rows[0]), rows)

    l2_rows = []
    for i, capture_index in enumerate(indices):
        centre = capture_index + 1
        for channel in range(7):
            for component in range(2):
                if l2_saturation[i, channel, component]:
                    l2_rows.append(dict(capture_index_zero_based=int(capture_index), input_centre_index=int(centre),
                                        branch_zero_based=channel, component='IQ'[component],
                                        value_before_l2_clip=float(fixed['l2_long'][centre, channel, component] / 512),
                                        value_after_l2_clip=int(fixed['l2'][centre, channel, component])))
    write_csv(HERE / 'l2_saturation_points.csv', list(l2_rows[0]), l2_rows)
    # Portable input memories for the accompanying RTL testbench.
    sim = HERE / 'simulation'
    sim.mkdir(exist_ok=True)
    (sim / 'coefficients.mem').write_text('\n'.join(f'{int(v)&65535:04x}' for v in p['raw']) + '\n')
    (sim / 'samples.mem').write_text('\n'.join(f'{((int(q)&65535)<<16)|(int(i)&65535):08x}' for i, q in x) + '\n')
    plot(x, measured, fixed, indices, reference_indices, clips)
    print(json.dumps(summary, indent=2))


def plot(x, measured, fixed, indices, reference_indices, clips):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False})
    figure, axes = plt.subplots(3, 1, figsize=(12, 10), constrained_layout=True)
    for ax in axes[:2]:
        ax.plot(indices, measured[indices, 1], color='#334155', linewidth=1.2, label='Captured Q = fixed reference Q')
        ax.plot(indices, fixed['accumulator'][reference_indices, 1] / 4096, color='#0891b2',
                linewidth=1, linestyle='--', label='Q before final clipping')
        ax.scatter(clips, measured[clips, 1], color='#dc2626', s=24, zorder=5, label='16 clipped points')
        ax.axhline(-32768, color='#dc2626', linewidth=0.8, linestyle=':')
        ax.set_ylabel('Output integer (Q1.15)')
        ax.grid(alpha=0.15)
    axes[0].set_title('All 16 negative-Q clipping points are reproduced exactly by the RTL arithmetic reference', loc='left', fontweight='bold')
    axes[0].legend(loc='upper right', fontsize=9)
    axes[0].set_xlim(23, 998)
    axes[1].set_xlim(540, 558)
    axes[1].set_ylim(-43000, 5000)
    axes[1].set_title('Close-up: captured indices 548-551 saturate at -32768', loc='left')
    ax = axes[2]
    for component, colour in enumerate(('#7c3aed', '#ea580c')):
        ax.plot(indices, fixed['l2_long'][reference_indices, 4, component] / 512,
                color=colour, linewidth=0.9, label=f'Branch 5 {"IQ"[component]} before L2 clipping')
    ax.axhline(-32768, color='#475569', linestyle='--', linewidth=0.8)
    ax.axhline(32767, color='#475569', linestyle='--', linewidth=0.8)
    ax.set_title('A separate intermediate limitation: branch 5 has 58 I/Q clipping events', loc='left')
    ax.set_ylabel('L2 integer (Q2.14)')
    ax.set_xlabel('Captured sample index (zero based; reference centred at input index + 1)')
    ax.set_xlim(23, 998)
    ax.legend(loc='upper right', fontsize=9)
    ax.grid(alpha=0.15)
    figure.savefig(HERE / 'clipping_audit.png', dpi=160)
    plt.close(figure)


if __name__ == '__main__':
    main()
