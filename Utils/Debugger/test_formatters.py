#!/usr/bin/env python3
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Collections open source project
##
## Copyright (c) 2026 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
##
## SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
##
##===----------------------------------------------------------------------===##

"""
Integration test for LLDB data formatters.

Testing LLDB data formatters requires:
  1. A "fixture" executable that exercises swift-collection data types
  2. An LLDB instance to launch and control the fixture
  3. A test runner that coordinates the fixture process with with test suite execution

The test fixture is built with SwiftPM. LLDB launches the fixture binary and
controls its process. Breakpoints are used to specify checkpoints for
validation. At each checkpoint, an "actual" value (a swift-collections data
type) is tested against a known good "expected" value (a core Swift data type,
for example Array).

Usage:
    python3 Utils/Debugger/test_formatters.py [--verbose]

The test runner uses Python's unittest module. Run with `--help` to see all options.
"""

import os
import sys
import subprocess
import unittest


def _run(cmd, **kwargs) -> str:
    return subprocess.check_output(cmd, **kwargs, text=True).rstrip()


def _xcode_run(cmd, **kwargs) -> str:
    full_cmd = ["xcrun", "-sdk", "macosx"]
    full_cmd.extend(cmd)
    return _run(full_cmd, **kwargs)


# Import the lldb module from the active toolchain.
try:
    import lldb
except ImportError:
    lldb_module_path = _xcode_run(("lldb", "-P"))
    if lldb_module_path not in sys.path:
        sys.path.insert(0, lldb_module_path)
    import lldb


class TestRigidArrayFormatter(unittest.TestCase):
    """Verify the RigidArray LLDB synthetic formatter."""

    @classmethod
    def _build(cls) -> str:
        """Build the test fixture with SwiftPM and return the binary path."""
        target = "FormatterFixtures"
        repo_root = _run(("git", "rev-parse", "--show-toplevel"))
        _xcode_run(("swift", "build", "--product", target), cwd=repo_root)
        bin_dir = _xcode_run(("swift", "build", "--show-bin-path"), cwd=repo_root)
        return os.path.join(bin_dir, target)

    @classmethod
    def _launch(cls, binary: str) -> None:
        debugger = lldb.SBDebugger.Create()
        debugger.SetAsync(False)

        target = debugger.CreateTarget(binary)
        assert target.IsValid(), f"failed to create target: {binary}"

        bp = target.BreakpointCreateByName("main")
        assert (
            bp.IsValid() and bp.GetNumLocations() > 0
        ), "could not set initial breakpoint"

        process = target.LaunchSimple(None, None, None)
        assert process.IsValid(), "failed to launch process"

        cls.debugger = debugger
        cls.process = process

    @classmethod
    def setUpClass(cls) -> None:
        binary = cls._build()
        cls._launch(binary)

    @classmethod
    def tearDownClass(cls) -> None:
        lldb.SBDebugger.Destroy(cls.debugger)

    def setUp(self) -> None:
        super().setUp()
        self.assertEqual(
            self.process.GetState(),
            lldb.eStateStopped,
            "process not set up in stopped state",
        )

    def _run_to_function(self, func_name: str) -> None:
        result = lldb.SBCommandReturnObject()
        self.debugger.GetCommandInterpreter().HandleCommand(
            f"breakpoint set -p breakHere -X {func_name}", result
        )
        self.assertTrue(
            result.Succeeded(),
            f"failed to set breakpoint in {func_name}: {result.GetError()}",
        )
        self.process.Continue()
        self.assertEqual(
            self.process.GetState(),
            lldb.eStateStopped,
            f"process not stopped after continuing to {func_name}",
        )

    @property
    def frame(self) -> lldb.SBFrame:
        return self.process.selected_thread.selected_frame

    def test_1_empty(self):
        self._run_to_function("testEmpty")
        actual = self.frame.var("actual")
        expected = self.frame.var("expected")
        self._assertEqualValues(actual, expected)

    def test_2_under_capacity(self):
        self._run_to_function("testUnderCapacity")
        actual = self.frame.var("actual")
        expected = self.frame.var("expected")
        self._assertEqualValues(actual, expected)

    def test_3_full_capacity(self):
        self._run_to_function("testFullCapacity")
        actual = self.frame.var("actual")
        expected = self.frame.var("expected")
        self._assertEqualValues(actual, expected)

    def _assertEqualValues(self, actual, expected):
        self.assertEqual(
            actual.num_children,
            expected.num_children,
            f"value has the wrong number of children",
        )
        for actual_child, expected_child in zip(actual, expected):
            self.assertEqual(
                str(actual_child), str(expected_child), "child value differs"
            )


if __name__ == "__main__":
    unittest.main()
