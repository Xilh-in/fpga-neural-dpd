import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def module(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    result = importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result


golden = module('golden', 'fpga-golden-check/scripts/golden_check.py')
bounded = module('bounded', 'fpga-bounded-io/scripts/bounded_io.py')
INCLUDE_PYNQ = os.environ.get('SKILL_INCLUDE_PYNQ') == '1'
pynq = module('pynq_contract', 'extensions/pynq-overlay-contract/scripts/overlay_contract.py') if INCLUDE_PYNQ else None
handoff = module('handoff', 'fpga-repro-handoff/scripts/package_check.py')
zynq = module('zynq_platform', 'zynq-baremetal-bringup/scripts/platform_check.py')


class Clock:
    def __init__(self): self.value = 0
    def __call__(self): self.value += 0.01; return self.value


class Transport:
    def __init__(self, response=b'', writes=3):
        self.data, self.sent, self.writes = bytearray(response), bytearray(), writes
    def read(self, n):
        result = bytes(self.data[:min(1,n)]); del self.data[:len(result)]; return result
    def write(self, data):
        count = min(len(data),self.writes);self.sent.extend(data[:count]);return count


class GoldenTests(unittest.TestCase):
    def setUp(self):
        path = ROOT / 'fpga-golden-check/assets'
        self.contract = json.loads((path/'contract.json').read_text())
        self.capture = golden.load_csv(path/'capture.csv', self.contract['capture_columns'])
        self.reference = golden.load_csv(path/'reference.csv', self.contract['reference_columns'])
        self.preclip = golden.load_csv(path/'reference.csv', self.contract['preclip_columns'])
    def test_demo_exact_with_overflow_proof(self):
        r=golden.compare(self.capture,self.reference,self.contract,self.preclip)
        self.assertEqual(r['exact_scalar_matches'],10);self.assertTrue(r['all_rail_hits_proven_overflow'])
    def test_wrong_offset_detected(self):
        self.contract['offset']=0
        self.assertEqual(golden.compare(self.capture,self.reference,self.contract)['status'],'FAIL')
    def test_corrupted_golden_detected(self):
        self.reference[3][1]+=1
        self.assertGreater(golden.compare(self.capture,self.reference,self.contract)['mismatch_count'],0)
    def test_outside_window_rejected(self):
        self.contract['stop']=7
        with self.assertRaises(ValueError): golden.compare(self.capture,self.reference,self.contract)
    def test_endpoint_not_equated_with_overflow(self):
        c=dict(capture_columns=['x'],reference_columns=['x'],bits=16)
        r=golden.compare([[-32768]],[[-32768]],c,[[-32768]])
        self.assertEqual(r['status'],'PASS');self.assertFalse(r['all_rail_hits_proven_overflow'])
    def test_different_three_channel_12bit_case(self):
        c=dict(capture_columns=['a','b','c'],reference_columns=['r','s','t'],bits=12,offset=2)
        x=[[1,2,3],[-2048,0,2047]]
        self.assertEqual(golden.compare(x,[[0]*3,[0]*3]+x,c)['status'],'PASS')
    def test_nonfinite_csv_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'bad.csv';p.write_text('x\nnan\n')
            with self.assertRaises(ValueError): golden.load_csv(p,['x'])
    def test_unsigned_input_range(self):
        c=dict(capture_columns=['a'],reference_columns=['b'],bits=8,signed=False)
        with self.assertRaises(ValueError): golden.compare([[-1]],[[-1]],c)
    def test_nan_reference_cannot_pass_library_comparison(self):
        c=dict(capture_columns=['a'],reference_columns=['b'])
        with self.assertRaises(ValueError): golden.compare([[0]],[[float('nan')]],c)


class BoundedTests(unittest.TestCase):
    def test_binary_lf_and_partial_io(self):
        io_device=Transport(b'\x0a\x00\x00\x80\n');s=bounded.Session(io_device,Clock())
        self.assertEqual(s.transfer(b'Read\n',4,1,trailer=b'\n'),b'\x0a\x00\x00\x80')
        self.assertEqual(io_device.sent,b'Read\n')
    def test_short_packet_invalidates_and_logs(self):
        log=io.StringIO();s=bounded.Session(Transport(b'\x01'),Clock(),log)
        with self.assertRaises(TimeoutError): s.transfer(b'R',4,0.1)
        self.assertTrue(s.invalid);self.assertIn('"error"',log.getvalue())
        with self.assertRaises(bounded.SessionError): s.transfer(b'R',4,1)
    def test_error_ack(self):
        s=bounded.Session(Transport(b'ERR RANGE\n'),Clock())
        with self.assertRaises(bounded.SessionError): s.transfer(b'W',0,1,trailer=b'\n',ack_only=True)
    def test_write_stall(self):
        s=bounded.Session(Transport(writes=0),Clock())
        with self.assertRaises(bounded.SessionError): s.transfer(b'W',0,1)
    def test_bad_trailer(self):
        s=bounded.Session(Transport(b'12!'),Clock())
        with self.assertRaises(bounded.SessionError): s.transfer(b'R',2,1,trailer=b'\n')
    def test_poll_stuck_low_and_high(self):
        for actual,expected in ((0,1),(1,0)):
            with self.assertRaises(TimeoutError): bounded.poll(lambda:actual,expected,0.05,Clock(),lambda _:None)
    def test_poll_completes(self):
        self.assertEqual(bounded.poll(lambda:1,1,1,Clock(),lambda _:None),1)


class FakeOverlay:
    def __init__(self, metadata): self.ip_dict=copy.deepcopy(metadata);self.loaded=False;self.downloads=0
    def is_loaded(self): return self.loaded
    def download(self): self.downloads+=1;self.loaded=True


class FakeMMIO:
    def __init__(self, base, size): self.base,self.size,self.values,self.writes=base,size,{},[]
    def read(self, offset): return self.values.get(offset,0)
    def write(self, offset, value): self.values[offset]=value;self.writes.append((offset,value))


@unittest.skipUnless(INCLUDE_PYNQ, 'Optional PYNQ extension is not part of the Zynq bare-metal profile')
class PynqTests(unittest.TestCase):
    def setUp(self):
        path=ROOT/'extensions/pynq-overlay-contract/assets'
        self.c=json.loads((path/'contract_a.json').read_text());self.m=json.loads((path/'metadata_a.json').read_text())
        self.ol=FakeOverlay(self.m);self.io=None
        def factory(base,size): self.io=FakeMMIO(base,size);return self.io
        self.session=pynq.RegisterSession(self.ol,self.c,factory)
    def test_two_different_metadata_profiles(self):
        path=ROOT/'extensions/pynq-overlay-contract/assets'
        for name in ('a','b'):
            c=json.loads((path/f'contract_{name}.json').read_text());m=json.loads((path/f'metadata_{name}.json').read_text())
            self.assertEqual(pynq.validate_contract(c,m)['status'],'PASS')
    def test_wrong_type(self):
        self.c['expected_type']='wrong'
        with self.assertRaises(ValueError): pynq.validate_contract(self.c,self.m)
    def test_offset_outside_range(self):
        self.c['registers']['start']['offset']=4096
        with self.assertRaises(ValueError): pynq.validate_contract(self.c,self.m)
    def test_unaligned_offset(self):
        self.c['registers']['start']['offset']=3
        with self.assertRaises(ValueError): pynq.validate_contract(self.c,self.m)
    def test_not_loaded_blocks_mmio(self):
        with self.assertRaises(RuntimeError): self.session.read('status')
        self.assertIsNone(self.io)
    def test_ro_wo_and_read_side_effect_guard(self):
        self.ol.loaded=True
        with self.assertRaises(ValueError): self.session.write('status',1)
        with self.assertRaises(ValueError): self.session.read('start')
        self.c['registers']['length']['read_safe']=False
        with self.assertRaises(ValueError): self.session.read('length')
    def test_value_range_and_valid_transfer(self):
        self.ol.loaded=True
        with self.assertRaises(ValueError): self.session.write('length',5000)
        self.session.write('length',32);self.assertEqual(self.session.read('length'),32)
        self.assertEqual(self.io.writes,[(4,32)])
    def test_mapping_change_blocked(self):
        self.ol.loaded=True;self.session.read('status')
        self.ol.ip_dict['filter_core']['phys_addr']+=4096
        with self.assertRaises(RuntimeError): self.session.read('status')
    def test_poll_deadline(self):
        self.ol.loaded=True
        with self.assertRaises(TimeoutError): self.session.wait_value('status',1,timeout=0.05,clock=Clock(),sleep=lambda _:None)
    def test_missing_hwh_prevents_factory_call(self):
        with tempfile.TemporaryDirectory() as tmp:
            bit=Path(tmp)/'test.bit';bit.write_bytes(b'MOCK-NOT-A-REAL-BITSTREAM')
            def factory(*args,**kwargs): self.fail('factory must not run')
            with self.assertRaises(ValueError): pynq.open_overlay(bit,self.c,overlay_factory=factory)
    def test_default_no_download_then_explicit_download(self):
        with tempfile.TemporaryDirectory() as tmp:
            bit=Path(tmp)/'test.bit';bit.write_bytes(b'MOCK-NOT-A-REAL-BITSTREAM');bit.with_suffix('.hwh').write_text('MOCK')
            calls=[]
            def factory(path,download): calls.append(download);return self.ol
            pynq.open_overlay(bit,self.c,overlay_factory=factory)
            self.assertEqual(calls,[False]);self.assertEqual(self.ol.downloads,0)
            pynq.open_overlay(bit,self.c,program=True,overlay_factory=factory)
            self.assertEqual(self.ol.downloads,1)
    def test_invalid_contract_prevents_programming(self):
        with tempfile.TemporaryDirectory() as tmp:
            bit=Path(tmp)/'test.bit';bit.write_bytes(b'MOCK');bit.with_suffix('.hwh').write_text('MOCK')
            self.c['ip']='missing'
            with self.assertRaises(ValueError): pynq.open_overlay(bit,self.c,program=True,overlay_factory=lambda *a,**k:self.ol)
            self.assertEqual(self.ol.downloads,0)
    def test_export_ignores_device_objects(self):
        self.ol.ip_dict['filter_core']['device']=object()
        with tempfile.TemporaryDirectory() as tmp:
            output=Path(tmp)/'metadata.json'
            result=pynq.export_metadata(self.ol,output)
            self.assertEqual(set(result['filter_core']),{'phys_addr','addr_range','type'})
            self.assertEqual(json.loads(output.read_text())['filter_core']['phys_addr'],1073741824)


class ZynqTests(unittest.TestCase):
    def setUp(self):
        self.path=ROOT/'zynq-baremetal-bringup/assets'
        self.profile=json.loads((self.path/'rk7100_profile.json').read_text())
    def test_rk7100_standalone_profile(self):
        r=zynq.check(self.profile,self.path/'mock_xpr.xml',self.path/'mock_app.xml')
        self.assertEqual((r['part'],r['processor'],r['runtime']),('xc7z100ffg900-2','ps7_cortexa9_0','standalone'))
    def test_tutorial_z020_mismatch_rejected(self):
        self.profile['part']='xc7z020clg484-2'
        with self.assertRaises(ValueError):zynq.check(self.profile,self.path/'mock_xpr.xml',self.path/'mock_app.xml')
    def test_wrong_processor_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            app=Path(tmp)/'app.xml';app.write_text('<SdkProject cpuInstance="psu_cortexa53_0" os="standalone"/>')
            with self.assertRaises(ValueError):zynq.check(self.profile,self.path/'mock_xpr.xml',app)
    def test_linux_application_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            app=Path(tmp)/'app.xml';app.write_text('<SdkProject cpuInstance="ps7_cortexa9_0" os="linux"/>')
            with self.assertRaises(ValueError):zynq.check(self.profile,self.path/'mock_xpr.xml',app)
    def test_missing_part_not_guessed(self):
        with tempfile.TemporaryDirectory() as tmp:
            xpr=Path(tmp)/'pl.xml';xpr.write_text('<Project/>')
            with self.assertRaises(ValueError):zynq.check(self.profile,xpr,self.path/'mock_app.xml')
    def test_framework_profile_mismatch_rejected(self):
        self.profile['runtime']='pynq'
        with self.assertRaises(ValueError):zynq.check(self.profile,self.path/'mock_xpr.xml',self.path/'mock_app.xml')
    def test_second_a9_core_requires_matching_explicit_profile(self):
        self.profile['processor']='ps7_cortexa9_1'
        with tempfile.TemporaryDirectory() as tmp:
            app=Path(tmp)/'app.xml';app.write_text('<SdkProject cpuInstance="ps7_cortexa9_1" os="standalone"/>')
            self.assertEqual(zynq.check(self.profile,self.path/'mock_xpr.xml',app)['processor'],'ps7_cortexa9_1')


class HandoffTests(unittest.TestCase):
    def project(self, root):
        src=root/'source';shutil.copytree(ROOT/'fpga-repro-handoff/assets/demo_project',src);return src
    def test_fresh_extraction_demo(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);src=self.project(root);archive=root/'demo.zip'
            handoff.pack(src,archive);r=handoff.smoke(archive,[sys.executable,'main.py'])
            self.assertEqual(r['exit_code'],0);self.assertIn('PORTABLE_DEMO_PASS',r['stdout'])
    def test_corruption_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);src=self.project(root);archive=root/'demo.zip';handoff.pack(src,archive)
            target=root/'unpacked'
            with zipfile.ZipFile(archive) as z: z.extractall(target)
            (target/'settings.json').write_text('{}')
            with self.assertRaises(ValueError): handoff.verify(target)
    def test_unmanifested_code_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);src=self.project(root);archive=root/'demo.zip';handoff.pack(src,archive)
            target=root/'unpacked'
            with zipfile.ZipFile(archive) as z: z.extractall(target)
            (target/'extra.py').write_text('print(1)')
            with self.assertRaises(ValueError): handoff.verify(target)
    def test_zip_traversal_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive=Path(tmp)/'bad.zip'
            with zipfile.ZipFile(archive,'w') as z:z.writestr('../escape.py','print(1)')
            with self.assertRaises(ValueError): handoff.smoke(archive,[sys.executable,'main.py'])
    def test_no_implicit_execution(self):
        with self.assertRaises(ValueError): handoff.smoke('unused.zip',[])
    def test_broken_relative_dependency_fails_smoke(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);src=self.project(root)
            (src/'main.py').write_text("open('../author_only/settings.json').read()")
            archive=root/'bad.zip';handoff.pack(src,archive)
            self.assertNotEqual(handoff.smoke(archive,[sys.executable,'main.py'])['exit_code'],0)


if __name__=='__main__':
    unittest.main(verbosity=2)
