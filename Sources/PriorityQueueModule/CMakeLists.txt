#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(PriorityQueueModule
  _Node.swift
  Heap.swift
  Heap+ExpressibleByArrayLiteral.swift
  Heap+Invariants.swift
  Heap+UnsafeHandle.swift)
set_target_properties(PriorityQueueModule PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(PriorityQueueModule)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS PriorityQueueModule)
