#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name DequeModule)
  add_library(DequeModule
    ${COLLECTIONS_DEQUE_SOURCES})
  target_link_libraries(DequeModule PRIVATE
    InternalCollectionsUtilities
    ContainersPreview)
  set_target_properties(DequeModule PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(DequeModule)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS DequeModule)
endif()

target_sources(${module_name} PRIVATE
  "_UnsafeDequeSegments.swift"
  "_UnsafeDequeHandle.swift"
  "_DequeSlot.swift"
  "RigidDeque/RigidDeque.swift"
  "RigidDeque/RigidDeque+Append.swift"
  "RigidDeque/RigidDeque+Consumption.swift"
  "RigidDeque/RigidDeque+Container.swift"
  "RigidDeque/RigidDeque+Descriptions.swift"
  "RigidDeque/RigidDeque+Equatable.swift"
  "RigidDeque/RigidDeque+Experimental.swift"
  "RigidDeque/RigidDeque+Hashable.swift"
  "RigidDeque/RigidDeque+Initializers.swift"
  "RigidDeque/RigidDeque+Insertions.swift"
  "RigidDeque/RigidDeque+Prepend.swift"
  "RigidDeque/RigidDeque+Removals.swift"
  "RigidDeque/RigidDeque+Replacements.swift"
  "RigidDeque/RigidDeque+Testing.swift"
  "UniqueDeque/UniqueDeque.swift"
  "UniqueDeque/UniqueDeque+Append.swift"
  "UniqueDeque/UniqueDeque+Consumption.swift"
  "UniqueDeque/UniqueDeque+Container.swift"
  "UniqueDeque/UniqueDeque+Descriptions.swift"
  "UniqueDeque/UniqueDeque+Equatable.swift"
  "UniqueDeque/UniqueDeque+Experimental.swift"
  "UniqueDeque/UniqueDeque+Hashable.swift"
  "UniqueDeque/UniqueDeque+Initializers.swift"
  "UniqueDeque/UniqueDeque+Insertions.swift"
  "UniqueDeque/UniqueDeque+Prepend.swift"
  "UniqueDeque/UniqueDeque+Removals.swift"
  "UniqueDeque/UniqueDeque+Replacements.swift"
  "Deque/_DequeBuffer.swift"
  "Deque/Deque+Collection.swift"
  "Deque/Deque+CustomReflectable.swift"
  "Deque/Deque.swift"
  "Deque/Deque+Hashable.swift"
  "Deque/_DequeBufferHeader.swift"
  "Deque/Deque+Codable.swift"
  "Deque/Deque+Testing.swift"
  "Deque/Deque._UnsafeHandle.swift"
  "Deque/Deque+Descriptions.swift"
  "Deque/Deque+Extras.swift"
  "Deque/Deque+ExpressibleByArrayLiteral.swift"
  "Deque/Deque+Equatable.swift"
  "Deque/Deque._Storage.swift"
  )
