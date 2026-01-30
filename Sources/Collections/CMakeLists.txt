#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(Collections
    "BitCollections reexports.swift"
    "DequeModule reexports.swift"
    "HashTreeCollections reexports.swift"
    "HeapModule reexports.swift"
    "OrderedCollections reexports.swift")
target_link_libraries(Collections PRIVATE
  BitCollections
  DequeModule
  HashTreeCollections
  HeapModule
  OrderedCollections
  )
set_target_properties(Collections PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(Collections)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS Collections)
