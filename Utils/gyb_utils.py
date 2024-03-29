#===-----------------------------------------------------------------------===//
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
# See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
#===-----------------------------------------------------------------------===//

def autogenerated_warning():
  return """
// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################
"""

visibility_levels = ["internal", "public"]
def visibility_boilerplate(part):
    if part == "internal":
        return """
// In single module mode, we need these declarations to be internal,
// but in regular builds we want them to be public. Unfortunately
// the current best way to do this is to duplicate all definitions.
#if COLLECTIONS_SINGLE_MODULE"""
        
    if part == "public":
        return "#else // !COLLECTIONS_SINGLE_MODULE"
    if part == "end":
        return "#endif // COLLECTIONS_SINGLE_MODULE"
