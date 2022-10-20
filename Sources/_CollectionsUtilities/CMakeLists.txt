#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(_CollectionsUtilities
  "_SortedCollection.swift"
  "_UniqueCollection.swift"
  "Array+WithContiguousStorage Compatibility.swift"
  "Debugging.swift"
  "Descriptions.swift"
  "IntegerTricks/FixedWidthInteger+roundUpToPowerOfTwo.swift"
  "IntegerTricks/Integer rank.swift"
  "IntegerTricks/UInt+first and last set bit.swift"
  "IntegerTricks/UInt+reversed.swift"
  "RandomAccessCollection+Offsets.swift"
  "UnsafeBufferPointer+Extras.swift"
  "UnsafeMutableBufferPointer+Extras.swift"
  "UnsafeMutableBufferPointer+SE-0370.swift"
  "UnsafeMutablePointer+SE-0370.swift"
  "UnsafeRawPointer extensions.swift"
  )
set_target_properties(_CollectionsUtilities PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(_CollectionsUtilities)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS _CollectionsUtilities)
