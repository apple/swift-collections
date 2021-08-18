
#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(SparseSetModule
  SparseSet.swift
  SparseSet+Codable.swift
  SparseSet+CustomDebugStringConvertible.swift
  SparseSet+CustomStringConvertible.swift
  SparseSet+DenseStorage.swift
  SparseSet+Equatable.swift
  SparseSet+Elements.swift
  SparseSet+Elements+SubSequence.swift
  SparseSet+ExpressibleByDictionaryLiteral.swift
  SparseSet+Hashable.swift
  SparseSet+Initializers.swift
  SparseSet+Invariants.swift
  "SparseSet+Partial MutableCollection.swift"
  "SparseSet+Partial RangeReplaceableCollection.swift"
  SparseSet+Sequence.swift
  SparseSet+SparseStorage.swift
  SparseSet+Values.swift)
set_target_properties(SparseSetModule PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(SparseSetModule)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS SparseSetModule)
