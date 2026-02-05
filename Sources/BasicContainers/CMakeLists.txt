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
  "UniqueArray/UniqueArray+Descriptions.swift"
  "UniqueArray/UniqueArray+Equatable.swift"
  "UniqueArray/UniqueArray+Experimental.swift"
  "UniqueArray/UniqueArray+Hashable.swift"
  "UniqueArray/UniqueArray+Initializers.swift"
  "UniqueArray/UniqueArray+Insertions.swift"
  "UniqueArray/UniqueArray+Removals.swift"
  "UniqueArray/UniqueArray+Replacements.swift"
)
