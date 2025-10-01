#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(Collections
    "Collections.swift")
target_link_libraries(Collections PUBLIC
  BitCollections
  DequeModule
  HeapModule
  OrderedCollections
  HashTreeCollections # maybe _RopeModule is missing?
  )

_install_target(Collections)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS Collections)

# All the .exported targets from Package.swift
swift_module_re_exports(Collections BitCollections)
swift_module_re_exports(Collections DequeModule)
swift_module_re_exports(Collections HeapModule)
swift_module_re_exports(Collections OrderedCollections)
swift_module_re_exports(Collections HashTreeCollections) # maybe _RopeModule is missing?
