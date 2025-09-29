#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name InternalCollectionsUtilities)
  add_library(InternalCollectionsUtilities
    ${COLLECTIONS_UTILITIES_SOURCES})
  set_target_properties(InternalCollectionsUtilities PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(InternalCollectionsUtilities)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS InternalCollectionsUtilities)
endif()

target_sources(${module_name} PRIVATE
  "Debugging.swift"
  "Descriptions.swift"
  "LifetimeOverride.swift"
  "RandomAccessCollection+Offsets.swift"
  "UnsafeBufferPointer+Extras.swift"
  "UnsafeMutableBufferPointer+Extras.swift"
  "UnsafeRawBufferPointer+Extras.swift"
  "UnsafeMutableRawBufferPointer+Extras.swift"
  "IntegerTricks/FixedWidthInteger+roundUpToPowerOfTwo.swift"
  "IntegerTricks/Integer rank.swift"
  "IntegerTricks/UInt+first and last set bit.swift"
  "IntegerTricks/UInt+reversed.swift"
  "UnsafeBitSet/_UnsafeBitSet+Index.swift"
  "UnsafeBitSet/_UnsafeBitSet+_Word.swift"
  "UnsafeBitSet/_UnsafeBitSet.swift"
  "_SortedCollection.swift"
  "_UniqueCollection.swift"
  )
