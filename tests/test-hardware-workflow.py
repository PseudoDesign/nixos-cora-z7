"""Exercise launcher and Tcl orchestration without claiming Vivado validation.

Run with Python 3 including tkinter: python3 tests/test-hardware-workflow.py
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tkinter
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HardwareWorkflow(unittest.TestCase):
    def interpreter(self, directory, version='2026.1', progress='100%',
                    violation='', slack='0.1'):
        t = tkinter.Tcl()
        for key, value in dict(repo_root=str(ROOT), project_dir=str(directory),
                               jobs=4, tool_version=version, progress=progress,
                               violation=violation, slack=slack, exported=0).items():
            t.setvar(key, value)
        t.eval('''
            proc version {args} { return $::tool_version }
            proc current_project {args} { return "" }
            proc get_board_parts {args} { return digilentinc.com:cora-z7-07s:part0:1.1 }
            proc create_project {name dir args} { file mkdir $dir }
            proc create_bd_cell {args} { return processing_system7_0 }
            proc get_files {args} { return system.bd }
            proc make_wrapper {args} { return system_wrapper.v }
            proc get_filesets {args} { return sources_1 }
            proc get_runs {name} { return $name }
            proc get_drc_violations {args} { return $::violation }
            proc get_drc_checks {args} { return CHECK1 }
            proc get_timing_paths {args} { return path1 }
            proc get_property {property object} {
                switch -- $property {
                    PROGRESS { return $::progress }
                    STATUS { return "Mock status" }
                    CHECK { return CHECK1 }
                    SEVERITY { return Error }
                    SLACK { return $::slack }
                    default { error "Unexpected property $property" }
                }
            }
            foreach cmd {set_param set_property create_bd_design apply_bd_automation
                         validate_bd_design save_bd_design generate_target add_files
                         update_compile_order launch_runs wait_on_run open_run
                         report_drc report_timing_summary} {
                proc $cmd {args} {}
            }
            rename source real_source
            proc source {path} {
                if {[file tail $path] eq "export-hardware.tcl"} {
                    proc export_cora_release {args} { set ::exported 1 }
                } else { uplevel 1 [list real_source $path] }
            }
        ''')
        return t

    def test_build_gates(self):
        for name, options, expected in [
            ('success', {}, None),
            ('old-version', {'version': '2024.1'}, 'Expected Vivado'),
            ('failed-run', {'progress': '70%'}, 'Synthesis failed'),
            ('drc', {'violation': 'CHECK1-1'}, 'DRC failed'),
            ('timing', {'slack': '-0.1'}, 'Timing failed'),
        ]:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                t = self.interpreter(Path(tmp) / 'project with spaces', **options)
                script = str(ROOT / 'hw/build.tcl')
                if expected:
                    with self.assertRaisesRegex(tkinter.TclError, expected):
                        t.call('source', script)
                    self.assertEqual(int(t.getvar('exported')), 0)
                else:
                    t.call('source', script)
                    self.assertEqual(int(t.getvar('exported')), 1)

    def test_existing_gui_work_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            marker = Path(tmp) / 'unsaved-work.txt'
            marker.write_text('preserve me')
            t = self.interpreter(tmp)
            with self.assertRaisesRegex(tkinter.TclError, 'already exists'):
                t.call('source', str(ROOT / 'hw/create-project.tcl'))
            self.assertEqual(marker.read_text(), 'preserve me')

    def test_launcher_paths_and_exit_status(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            capture = tmp / 'args.json'
            fake = tmp / 'vivado'
            fake.write_text('#!/usr/bin/env python3\nimport json, os, sys\n'
                            'open(os.environ["CAPTURE"], "w").write(json.dumps(sys.argv[1:]))\n'
                            'sys.exit(int(os.environ.get("FAKE_EXIT", "0")))\n')
            fake.chmod(0o755)
            env = dict(os.environ, PATH=f'{tmp}:{os.environ["PATH"]}', CAPTURE=str(capture))
            launcher = str(ROOT / 'scripts/hardware.sh')
            result = subprocess.run([launcher, 'create', 'project with spaces', '2'],
                                    cwd=tmp, env=env, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            args = json.loads(capture.read_text())
            self.assertEqual(args[args.index('-tclargs') + 1:],
                             ['create', str(tmp / 'project with spaces'), '2'])
            project = tmp / 'project with spaces'
            project.mkdir()
            (project / 'cora-z7-07s.xpr').touch()
            result = subprocess.run([launcher, 'gui', str(project)], env=env, capture_output=True)
            self.assertEqual(result.returncode, 0)
            args = json.loads(capture.read_text())
            self.assertNotIn('-source', args)
            self.assertEqual(args[-1], str(project / 'cora-z7-07s.xpr'))
            result = subprocess.run([launcher, 'build', str(tmp / 'release')],
                                    env=dict(env, FAKE_EXIT='42'), capture_output=True)
            self.assertEqual(result.returncode, 42)


if __name__ == '__main__':
    unittest.main()
