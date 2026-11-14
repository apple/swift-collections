#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2026 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information

SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name LinkedListModule)
  add_library(LinkedListModule)
  target_link_libraries(LinkedListModule PRIVATE
    InternalCollectionsUtilities)
  set_target_properties(LinkedListModule PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(LinkedListModule)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS LinkedListModule)
endif()

target_sources(${module_name} PRIVATE
  "LinkedList.swift"
  "LinkedList+Append.swift"
  "LinkedList+ContainerOperations.swift"
  "LinkedList+Extract.swift"
  "LinkedList+Index.swift"
  "LinkedList+Insert.swift"
  "LinkedList+Iterable.swift"
  "LinkedList+Node.swift"
  "LinkedList+Prepend.swift"
  "LinkedList+Remove.swift"
  "LinkedList+Validation.swift"
  "LinkedList+Version.swift"
)
