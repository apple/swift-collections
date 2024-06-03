#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_SINGLE_MODULE)
  if (COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
    set(COLLECTIONS_MODULE_NAME _FoundationCollections)
    set(COLLECTIONS_MODULE_TYPE STATIC)
  else()
    set(COLLECTIONS_MODULE_NAME Collections)
    set(COLLECTIONS_MODULE_TYPE)
  endif()

  get_property(COLLECTIONS_UTILITIES_SOURCES GLOBAL PROPERTY COLLECTIONS_UTILITIES_SOURCES)
  list(TRANSFORM COLLECTIONS_UTILITIES_SOURCES PREPEND "../InternalCollectionsUtilities/")
  get_property(COLLECTIONS_BIT_SOURCES GLOBAL PROPERTY COLLECTIONS_BIT_SOURCES)
  list(TRANSFORM COLLECTIONS_BIT_SOURCES PREPEND "../BitCollections/")
  get_property(COLLECTIONS_DEQUE_SOURCES GLOBAL PROPERTY COLLECTIONS_DEQUE_SOURCES)
  list(TRANSFORM COLLECTIONS_DEQUE_SOURCES PREPEND "../DequeModule/")
  get_property(COLLECTIONS_HEAP_SOURCES GLOBAL PROPERTY COLLECTIONS_HEAP_SOURCES)
  list(TRANSFORM COLLECTIONS_HEAP_SOURCES PREPEND "../HeapModule/")
  get_property(COLLECTIONS_ORDERED_SOURCES GLOBAL PROPERTY COLLECTIONS_ORDERED_SOURCES)
  list(TRANSFORM COLLECTIONS_ORDERED_SOURCES PREPEND "../OrderedCollections/")
  get_property(COLLECTIONS_HASHTREE_SOURCES GLOBAL PROPERTY COLLECTIONS_HASHTREE_SOURCES)
  list(TRANSFORM COLLECTIONS_HASHTREE_SOURCES PREPEND "../HashTreeCollections/")

  add_library(${COLLECTIONS_MODULE_NAME} ${COLLECTIONS_MODULE_TYPE}
    "Collections.swift"
    ${COLLECTIONS_UTILITIES_SOURCES}
    ${COLLECTIONS_BIT_SOURCES}
    ${COLLECTIONS_DEQUE_SOURCES}
    ${COLLECTIONS_HEAP_SOURCES}
    ${COLLECTIONS_ORDERED_SOURCES}
    ${COLLECTIONS_HASHTREE_SOURCES})

  if(COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
    get_property(COLLECTIONS_ROPE_SOURCES GLOBAL PROPERTY COLLECTIONS_ROPE_SOURCES)
    list(TRANSFORM COLLECTIONS_ROPE_SOURCES PREPEND "../RopeModule/")
    target_sources(${COLLECTIONS_MODULE_NAME} PRIVATE
      ${COLLECTIONS_ROPE_SOURCES})
    target_compile_options(${COLLECTIONS_MODULE_NAME} PRIVATE
      "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-Xfrontend -allowable-client -Xfrontend FoundationEssentials>")
  endif()

  target_compile_definitions(${COLLECTIONS_MODULE_NAME} PRIVATE COLLECTIONS_SINGLE_MODULE)
  set_target_properties(${COLLECTIONS_MODULE_NAME} PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  if(COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
    # Install only the swift module and not the library
    if(BUILD_SHARED_LIBS)
      set(swift swift)
    else()
      set(swift swift_static)
    endif()
    get_swift_host_os(swift_os)
    get_swift_host_arch(swift_arch)
    install(FILES $<TARGET_PROPERTY:${COLLECTIONS_MODULE_NAME},Swift_MODULE_DIRECTORY>/${COLLECTIONS_MODULE_NAME}.swiftdoc
      DESTINATION lib/${swift}/${swift_os}/${COLLECTIONS_MODULE_NAME}.swiftmodule
      RENAME ${swift_arch}.swiftdoc)
    install(FILES $<TARGET_PROPERTY:${COLLECTIONS_MODULE_NAME},Swift_MODULE_DIRECTORY>/${COLLECTIONS_MODULE_NAME}.swiftmodule
      DESTINATION lib/${swift}/${swift_os}/${COLLECTIONS_MODULE_NAME}.swiftmodule
      RENAME ${swift_arch}.swiftmodule)
  else()
    _install_target(${COLLECTIONS_MODULE_NAME})
  endif()
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS ${COLLECTIONS_MODULE_NAME})
else()
  add_library(Collections
    "Collections.swift")
  target_link_libraries(Collections PRIVATE
    BitCollections
    DequeModule
    HeapModule
    OrderedCollections
    HashTreeCollections
    )
  set_target_properties(Collections PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

  _install_target(Collections)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS Collections)
endif()
