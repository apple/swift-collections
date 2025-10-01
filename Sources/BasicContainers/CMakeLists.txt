#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2025 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name BasicContainers)
  add_library(BasicContainers
    ${COLLECTIONS_ARRAY_SOURCES})
  target_link_libraries(BasicContainers PUBLIC
    InternalCollectionsUtilities ContainersPreview)

  _install_target(BasicContainers)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS BasicContainers)

  # Re-export InternalCollectionsUtilities so dependents can access it
  swift_module_re_exports(BasicContainers InternalCollectionsUtilities)
endif()

target_sources(${module_name} PRIVATE
  "RigidArray.swift"
  "RigidArray+Append.swift"
  "RigidArray+Experimental.swift"
  "RigidArray+Initializers.swift"
  "RigidArray+Insertions.swift"
  "RigidArray+Removals.swift"
  "RigidArray+Replacements.swift"
  "UniqueArray.swift"
  "UniqueArray+Append.swift"
  "UniqueArray+Experimental.swift"
  "UniqueArray+Initializers.swift"
  "UniqueArray+Insertions.swift"
  "UniqueArray+Removals.swift"
  "UniqueArray+Replacements.swift"
)
