#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2025 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name ArrayModule)
  add_library(ArrayModule
    ${COLLECTIONS_ARRAY_SOURCES})
  target_link_libraries(ArrayModule PRIVATE
    InternalCollectionsUtilities ContainersPreview)
  set_target_properties(ArrayModule PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(ArrayModule)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS ArrayModule)
endif()

target_sources(${module_name} PRIVATE
  "DynamicArray.swift"
  "RigidArray.swift"
)
