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

import lldb


class RigidArraySynthetic:
    valobj: lldb.SBValue
    storage: lldb.SBValue
    count: int

    def __init__(self, valobj: lldb.SBValue, _) -> None:
        self.valobj = valobj

    def num_children(self) -> int:
        return self.count

    def get_child_at_index(self, idx: int) -> lldb.SBValue:
        return self.storage.GetChildAtIndex(idx)

    def update(self) -> bool:
        self.storage = self.valobj.GetChildMemberWithName(
            "_storage"
        ).GetSyntheticValue()
        self.count = (
            self.valobj.GetChildMemberWithName("_count")
            .GetSyntheticValue()
            .GetValueAsUnsigned()
        )
        return True
