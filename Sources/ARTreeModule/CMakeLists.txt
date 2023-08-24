#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2023 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(ARTreeModule
  "ArtNode.swift"
  "ARTree+insert.swift"
  "ARTree.swift"
  "FixedArray+impl.swift"
  "FixedSizedArray.swift"
  "Node+StringConverter.swift"
  "Node16.swift"
  "NodeHeader.swift"
  "RawNode.swift"
  "ARTree+delete.swift"
  "ARTree+Sequence.swift"
  "CMakeLists.txt"
  "FixedArray+Storage.swift"
  "InternalNode.swift"
  "Node+UnmanagedStorage.swift"
  "Node48.swift"
  "NodeLeaf.swift"
  "Utils.swift"
  "ARTree+get.swift"
  "ARTree+utils.swift"
  "Consts and Specs.swift"
  "FixedArray.swift"
  "Node+Storage.swif"
  "Node4.swift"
  "Node256.swift"
  "NodeType.swift"
)
target_link_libraries(ARTreeModule PRIVATE
  _CollectionsUtilities)
set_target_properties(ARTreeModule PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(ARTreeModule)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS ARTreeModule)
