#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2025 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name TrailingElementsModule)
  add_library(TrailingElementsModule)

  _install_target(TrailingElementsModule)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS TrailingElementsModule)

  # Re-export InternalCollectionsUtilities so dependents can access it
  swift_module_re_exports(TrailingElementsModule InternalCollectionsUtilities)
endif()

target_sources(${module_name} PRIVATE
  "TrailingArray.swift"
  "TrailingElements.swift"
  "TrailingPadding.swift")
