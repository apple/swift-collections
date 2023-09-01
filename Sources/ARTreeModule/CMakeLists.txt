#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2023 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(ARTreeModule
  "ARTree/ArtNode.swift"
  "ARTree/ARTree+insert.swift"
  "ARTree/ARTree.swift"
  "ARTree/FixedArray+impl.swift"
  "ARTree/FixedSizedArray.swift"
  "ARTree/Node+StringConverter.swift"
  "ARTree/Node16.swift"
  "ARTree/NodeHeader.swift"
  "ARTree/RawNode.swift"
  "ARTree/ARTree+delete.swift"
  "ARTree/ARTree+Sequence.swift"
  "ARTree/CMakeLists.txt"
  "ARTree/FixedArray+Storage.swift"
  "ARTree/InternalNode.swift"
  "ARTree/Node+UnmanagedStorage.swift"
  "ARTree/Node48.swift"
  "ARTree/NodeLeaf.swift"
  "ARTree/Utils.swift"
  "ARTree/ARTree+get.swift"
  "ARTree/ARTree+utils.swift"
  "ARTree/Consts and Specs.swift"
  "ARTree/FixedArray.swift"
  "ARTree/Node+Storage.swif"
  "ARTree/Node4.swift"
  "ARTree/Node256.swift"
  "ARTree/NodeType.swift"
)
target_link_libraries(ARTreeModule PRIVATE
  _CollectionsUtilities)
set_target_properties(ARTreeModule PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(ARTreeModule)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS ARTreeModule)
