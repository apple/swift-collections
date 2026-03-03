#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name BasicContainers)
  add_library(BasicContainers
    ${COLLECTIONS_ARRAY_SOURCES})
  target_link_libraries(BasicContainers PRIVATE
    InternalCollectionsUtilities ContainersPreview)
  set_target_properties(BasicContainers PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(BasicContainers)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS BasicContainers)
endif()

target_sources(${module_name} PRIVATE
  "RigidArray/RigidArray.swift"
  "RigidArray/RigidArray+Append.swift"
  "RigidArray/RigidArray+Consumption.swift"
  "RigidArray/RigidArray+Container.swift"
  "RigidArray/RigidArray+Deprecated.swift"
  "RigidArray/RigidArray+Descriptions.swift"
  "RigidArray/RigidArray+Equatable.swift"
  "RigidArray/RigidArray+Experimental.swift"
  "RigidArray/RigidArray+Hashable.swift"
  "RigidArray/RigidArray+Initializers.swift"
  "RigidArray/RigidArray+Insertions.swift"
  "RigidArray/RigidArray+Removals.swift"
  "RigidArray/RigidArray+Replacements.swift"
  "UniqueArray/UniqueArray.swift"
  "UniqueArray/UniqueArray+Append.swift"
  "UniqueArray/UniqueArray+Consumption.swift"
  "UniqueArray/UniqueArray+Container.swift"
  "UniqueArray/UniqueArray+Deprecated.swift"
  "UniqueArray/UniqueArray+Descriptions.swift"
  "UniqueArray/UniqueArray+Equatable.swift"
  "UniqueArray/UniqueArray+Experimental.swift"
  "UniqueArray/UniqueArray+Hashable.swift"
  "UniqueArray/UniqueArray+Initializers.swift"
  "UniqueArray/UniqueArray+Insertions.swift"
  "UniqueArray/UniqueArray+Removals.swift"
  "UniqueArray/UniqueArray+Replacements.swift"
  "HashTable/ProtocolGeneralizations.swift"
  "HashTable/_HTable.swift"
  "HashTable/_HTable+Bitmap.swift"
  "HashTable/_HTable+Bucket.swift"
  "HashTable/_HTable+Consumption.swift"
  "HashTable/_HTable+Debugging.swift"
  "HashTable/_HTable+Find.swift"
  "HashTable/_HTable+Insert.swift"
  "HashTable/_HTable+Iteration.swift"
  "HashTable/_HTable+Removal.swift"
  "HashTable/_HTable+Resizing.swift"
  "HashTable/_HTable+Sizing.swift"
  "HashTable/ProtocolGeneralizations.swift"
  "RigidSet/RigidSet.swift"
  "RigidSet/RigidSet+BorrowingSequence.swift"
  "RigidSet/RigidSet+Consumption.swift"
  "RigidSet/RigidSet+Debugging.swift"
  "RigidSet/RigidSet+Equatable.swift"
  "RigidSet/RigidSet+Hashable.swift"
  "RigidSet/RigidSet+Index.swift"
  "RigidSet/RigidSet+Initializers.swift"
  "RigidSet/RigidSet+Insertions.swift"
  "RigidSet/RigidSet+Lookup.swift"
  "RigidSet/RigidSet+Removals.swift"
  "RigidSet/RigidSet+Resizing.swift"
  "UniqueSet/UniqueSet.swift"
  "UniqueSet/UniqueSet+BorrowingSequence.swift"
  "UniqueSet/UniqueSet+Consumption.swift"
  "UniqueSet/UniqueSet+Debugging.swift"
  "UniqueSet/UniqueSet+Equatable.swift"
  "UniqueSet/UniqueSet+Hashable.swift"
  "UniqueSet/UniqueSet+Index.swift"
  "UniqueSet/UniqueSet+Initializers.swift"
  "UniqueSet/UniqueSet+Insertions.swift"
  "UniqueSet/UniqueSet+Lookup.swift"
  "UniqueSet/UniqueSet+Removals.swift"
  "UniqueSet/UniqueSet+Resizing.swift"
  "RigidDictionary/RigidDictionary.swift"
  "RigidDictionary/RigidDictionary+Consumption.swift"
  "RigidDictionary/RigidDictionary+Equatable.swift"
  "RigidDictionary/RigidDictionary+Hashable.swift"
  "RigidDictionary/RigidDictionary+Index.swift"
  "RigidDictionary/RigidDictionary+Indices.swift"
  "RigidDictionary/RigidDictionary+Initializers.swift"
  "RigidDictionary/RigidDictionary+Insertions.swift"
  "RigidDictionary/RigidDictionary+Keys.swift"
  "RigidDictionary/RigidDictionary+Lookup.swift"
  "RigidDictionary/RigidDictionary+Removals.swift"
  "RigidDictionary/RigidDictionary+Resizing.swift"
  "UniqueDictionary/UniqueDictionary.swift"
  "UniqueDictionary/UniqueDictionary+Consumption.swift"
  "UniqueDictionary/UniqueDictionary+Equatable.swift"
  "UniqueDictionary/UniqueDictionary+Hashable.swift"
  "UniqueDictionary/UniqueDictionary+Index.swift"
  "UniqueDictionary/UniqueDictionary+Indices.swift"
  "UniqueDictionary/UniqueDictionary+Initializers.swift"
  "UniqueDictionary/UniqueDictionary+Insertions.swift"
  "UniqueDictionary/UniqueDictionary+Keys.swift"
  "UniqueDictionary/UniqueDictionary+Lookup.swift"
  "UniqueDictionary/UniqueDictionary+Removals.swift"
  "UniqueDictionary/UniqueDictionary+Resizing.swift"
)
