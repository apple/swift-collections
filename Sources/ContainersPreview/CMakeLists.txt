#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2025 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name ContainersPreview)
  add_library(ContainersPreview
    ${COLLECTIONS_CONTAINERS_SOURCES})
  target_link_libraries(ContainersPreview PRIVATE
    InternalCollectionsUtilities)
  set_target_properties(ContainersPreview PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(ContainersPreview)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS ContainersPreview)
endif()

target_sources(${module_name} PRIVATE
  "BorrowIteratorProtocol.swift"
  "Box.swift"
  "Container.swift"
  "Container+Utilities.swift"
  "InputSpan.swift"
  "Mut.swift"
  "Ref.swift"
  "Shared.swift"
)
