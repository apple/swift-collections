#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(Future
  "LifetimeOverride.swift"
  "MutableRawSpan.swift"
  "MutableSpan.swift"
  "MutableSpanSlicing.swift"
  "OutputSpan.swift"
  "SpanExtensions.swift"
  "StdlibOutputSpanExtensions.swift"
  "UnsafeBufferPointer+Additions.swift"
)

target_link_libraries(Future PRIVATE
  InternalCollectionsUtilities)
set_target_properties(Future PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(Future)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS Future)
