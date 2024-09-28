#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(Future
  "Box.swift"
  "Cell.swift"
  "ContiguousStorage.swift"
  "Inout.swift"
  "OutputSpan.swift"
  "LifetimeOverride.swift"
  "RawSpan.swift"
  "Span.swift"
  "Span+Iterator.swift"
  "StdlibOutputSpanExtensions.swift"
  "StdlibSpanExtensions.swift"
  "Containers/Shared.swift"
  "Containers/Container.swift"
  "Containers/DynamicArray.swift"
  "Containers/NewArray.swift"
  "Containers/RigidArray.swift"
)

target_link_libraries(Future PRIVATE
  InternalCollectionsUtilities)
set_target_properties(Future PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(Future)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS Future)
