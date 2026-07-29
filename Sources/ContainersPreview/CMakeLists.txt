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
  "Conformances/Array+Iterable.swift"
  "Conformances/ClosedRange+Iterable.swift"
  "Conformances/InputSpan+Container.swift"
  "Conformances/InputSpan+Iterable.swift"
  "Conformances/MutableSpan+Container.swift"
  "Conformances/OutputSpan+Container.swift"
  "Conformances/Range+Iterable.swift"
  "Conformances/Span+Container.swift"
  "Protocols/Container/BidirectionalContainer.swift"
  "Protocols/Container/Container.swift"
  "Protocols/Container/Container+Filter.swift"
  "Protocols/Container/Container+SpanwiseZip.swift"
  "Protocols/Container/ContainerIterator.swift"
  "Protocols/Container/DynamicContainer.swift"
  "Protocols/Container/MutableContainer.swift"
  "Protocols/Container/PermutableContainer.swift"
  "Protocols/Container/PermutableContainer+HeapSort.swift"
  "Protocols/Container/PermutableContainer+MoveSubrange.swift"
  "Protocols/Container/PermutableContainer+Reverse.swift"
  "Protocols/Container/PermutableContainer+Shuffle.swift"
  "Protocols/Container/RandomAccessContainer.swift"
  "Protocols/Container/RangeExpression2.swift"
  "Protocols/Container/RangeReplaceableContainer.swift"
  "Protocols/Container/Strideable+Limits.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Copy.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+ElementsEqual.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Filter.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Map.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+MapError.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Reduce.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+SpanwiseZip.swift"
  "Protocols/Iterable/Iterable+ElementsEqual.swift"
  "Protocols/Iterable/Iterable+Reduce.swift"
  "Protocols/Iterable/Iterable+Utilities.swift"
  "Protocols/Drain/Drain.swift"
  "Protocols/Drain/Drain+Map.swift"
  "Protocols/Drain/Drain+Reduce.swift"
  "Protocols/Producer/CountedProducer.swift"
  "Protocols/Producer/Producer.swift"
  "Protocols/Producer/Producer+Collect.swift"
  "Protocols/Producer/Producer+Filter.swift"
  "Protocols/Producer/Producer+Map.swift"
  "Protocols/Producer/Producer+Reduce.swift"
  "Protocols/Producer/Producer+Unfold.swift"
  "Types/InputSpan.swift"
  "Types/MutableRef.swift"
  "Types/OutputSpan+Helpers.swift"
  "Types/Shared.swift"
  "Types/UniqueBox.swift"
)
