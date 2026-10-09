#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information

SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
#]]

if(COLLECTIONS_SINGLE_MODULE AND COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
  set(CONTAINERSPREVIEW_MODULE_NAME _FoundationContainersPreview)
else()
  set(CONTAINERSPREVIEW_MODULE_NAME ContainersPreview)
endif()

set(module_name ${CONTAINERSPREVIEW_MODULE_NAME})
add_library(${CONTAINERSPREVIEW_MODULE_NAME} ${COLLECTIONS_MODULE_TYPE})

if(COLLECTIONS_SINGLE_MODULE)
  target_link_libraries(${CONTAINERSPREVIEW_MODULE_NAME} PRIVATE ${COLLECTIONS_MODULE_NAME})

  if(COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
    target_compile_options(${CONTAINERSPREVIEW_MODULE_NAME} PRIVATE
      "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-Xfrontend -allowable-client -Xfrontend FoundationEssentials>")

    if(BUILD_SHARED_LIBS)
      # Install only the swift module and not the library
      set(swift swift)
    else()
      # Install both the swift module and the binary
      set(swift swift_static)
      install(TARGETS ${CONTAINERSPREVIEW_MODULE_NAME}
          ARCHIVE DESTINATION lib/swift_static/${COLLECTIONS_PLATFORM}$<$<BOOL:${COLLECTIONS_INSTALL_ARCH_SUBDIR}>:/${COLLECTIONS_ARCH}>
          LIBRARY DESTINATION lib/swift_static/${COLLECTIONS_PLATFORM}$<$<BOOL:${COLLECTIONS_INSTALL_ARCH_SUBDIR}>:/${COLLECTIONS_ARCH}>
          RUNTIME DESTINATION bin)
    endif()

    install(
      FILES $<TARGET_PROPERTY:${CONTAINERSPREVIEW_MODULE_NAME},Swift_MODULE_DIRECTORY>/${CONTAINERSPREVIEW_MODULE_NAME}.swiftdoc
      DESTINATION lib/${swift}/${COLLECTIONS_PLATFORM}/${CONTAINERSPREVIEW_MODULE_NAME}.swiftmodule
      RENAME ${COLLECTIONS_MODULE_TRIPLE}.swiftdoc)
    install(
      FILES $<TARGET_PROPERTY:${CONTAINERSPREVIEW_MODULE_NAME},Swift_MODULE_DIRECTORY>/${CONTAINERSPREVIEW_MODULE_NAME}.swiftmodule
      DESTINATION lib/${swift}/${COLLECTIONS_PLATFORM}/${CONTAINERSPREVIEW_MODULE_NAME}.swiftmodule
      RENAME ${COLLECTIONS_MODULE_TRIPLE}.swiftmodule)
  else()
    _install_target(${CONTAINERSPREVIEW_MODULE_NAME})
  endif()
else()
  target_link_libraries(${CONTAINERSPREVIEW_MODULE_NAME} PRIVATE
    InternalCollectionsUtilities SpanPreview BasicContainers DequeModule)
  _install_target(${CONTAINERSPREVIEW_MODULE_NAME})
endif()

set_target_properties(${CONTAINERSPREVIEW_MODULE_NAME} PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
set_property(GLOBAL
  APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS ${CONTAINERSPREVIEW_MODULE_NAME})

target_sources(${module_name} PRIVATE
  "Conformances/InputSpan+Container.swift"
  "Conformances/MutableSpan+Container.swift"
  "Conformances/OutputSpan+Container.swift"
  "Conformances/RigidArray+Container.swift"
  "Conformances/RigidDeque+Container.swift"
  "Conformances/RigidSet+Container.swift"
  "Conformances/Span+Container.swift"
  "Conformances/UniqueArray+Container.swift"
  "Conformances/UniqueSet+Container.swift"
  "Conformances/UniqueDeque+Container.swift"
  "Protocols/Container/BidirectionalContainer.swift"
  "Protocols/Container/Container.swift"
  "Protocols/Container/Container+Filter.swift"
  "Protocols/Container/Container+SpanwiseZip.swift"
  "Protocols/Container/ContainerIterator.swift"
  "Protocols/Container/DrainableContainer.swift"
  "Protocols/Container/DynamicContainer.swift"
  "Protocols/Container/MutableContainer.swift"
  "Protocols/Container/MutableContainer+UpdateSubrange.swift"
  "Protocols/Container/PermutableContainer.swift"
  "Protocols/Container/PermutableContainer+HeapSort.swift"
  "Protocols/Container/PermutableContainer+MoveSubrange.swift"
  "Protocols/Container/PermutableContainer+Reverse.swift"
  "Protocols/Container/PermutableContainer+Shuffle.swift"
  "Protocols/Container/RandomAccessContainer.swift"
  "Protocols/Container/RangeExpression2.swift"
  "Protocols/Container/RangeReplaceableContainer.swift"
  "Protocols/Container/Strideable+Limits.swift"
  "Protocols/Drain/ContainerDrain.swift"
  "Protocols/Drain/Drain.swift"
  "Protocols/Drain/Drain+Map.swift"
  "Protocols/Drain/Drain+Reduce.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Copy.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+ElementsEqual.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Filter.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Map.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+MapError.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+Reduce.swift"
  "Protocols/Iterable/BorrowingIteratorProtocol+SpanwiseZip.swift"
  "Protocols/Iterable/Iterable+ElementsEqual.swift"
  "Protocols/Iterable/Iterable+Reduce.swift"
  "Protocols/Producer/CountedProducer.swift"
  "Protocols/Producer/Producer.swift"
  "Protocols/Producer/Producer+Collect.swift"
  "Protocols/Producer/Producer+Filter.swift"
  "Protocols/Producer/Producer+Map.swift"
  "Protocols/Producer/Producer+Reduce.swift"
  "Protocols/Producer/Producer+Unfold.swift"
  "Types/Shared.swift"
  "Types/UniqueBox.swift"
)
