#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information

SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
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
  "Extensions/OutputSpan+Extras.swift"
  "Extensions/TemporaryAllocation.swift"
  "Protocols/Container/BidirectionalContainer.swift"
  "Protocols/Container/Container.swift"
  "Protocols/Container/Container+Filter.swift"
  "Protocols/Container/Container+SpanwiseZip.swift"
  "Protocols/Container/ContainerIterator.swift"
  "Protocols/Container/DynamicContainer.swift"
  "Protocols/Container/MutableContainer.swift"
  "Protocols/Container/PermutableContainer.swift"
  "Protocols/Container/RandomAccessContainer.swift"
  "Protocols/Container/RangeExpression2.swift"
  "Protocols/Container/RangeReplaceableContainer.swift"
  "Protocols/Container/Strideable+Limits.swift"
  "Protocols/BorrowingIteratorProtocol.swift"
  "Protocols/BorrowingIteratorProtocol+Copy.swift"
  "Protocols/BorrowingIteratorProtocol+ElementsEqual.swift"
  "Protocols/BorrowingIteratorProtocol+Filter.swift"
  "Protocols/BorrowingIteratorProtocol+Map.swift"
  "Protocols/BorrowingIteratorProtocol+Reduce.swift"
  "Protocols/BorrowingIteratorProtocol+SpanwiseZip.swift"
  "Protocols/BorrowingSequence.swift"
  "Protocols/BorrowingSequence+Standard Conformances.swift"
  "Protocols/BorrowingSequence+Utilities.swift"
  "Protocols/Drain.swift"
  "Protocols/Drain+Map.swift"
  "Protocols/Drain+Reduce.swift"
  "Protocols/Drain.swift"
  "Protocols/Producer.swift"
  "Protocols/Producer+Collect.swift"
  "Protocols/Producer+Filter.swift"
  "Protocols/Producer+Map.swift"
  "Protocols/Producer+Reduce.swift"
  "Types/Borrow.swift"
  "Types/Box.swift"
  "Types/Inout.swift"
  "Types/InputSpan.swift"
  "Types/Shared.swift"
)
