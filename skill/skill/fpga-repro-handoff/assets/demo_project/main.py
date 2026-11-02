"""A deliberately project-independent minimal smoke target."""
from pathlib import Path
import json

settings = json.loads((Path(__file__).resolve().parent / 'settings.json').read_text())
values = settings['values']
assert sum(values) == settings['expected_sum']
print('PORTABLE_DEMO_PASS')
