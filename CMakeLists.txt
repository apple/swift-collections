#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

cmake_minimum_required(VERSION 3.16)
project(SwiftCollections
  LANGUAGES C Swift)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

if(NOT SWIFT_SYSTEM_NAME)
  if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(SWIFT_SYSTEM_NAME macosx)
  else()
    set(SWIFT_SYSTEM_NAME "$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>")
  endif()
endif()

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)
set(CMAKE_Swift_COMPILE_OPTIONS_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)

if(CMAKE_SYSTEM_NAME STREQUAL Windows OR CMAKE_SYSTEM_NAME STREQUAL Darwin)
  option(BUILD_SHARED_LIBS "Build shared libraries by default" YES)
endif()

option(COLLECTIONS_SINGLE_MODULE "Build as a single module" NO)
option(COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE "Build a module for Foundation in the toolchain" NO)
option(COLLECTIONS_INSTALL_ARCH_SUBDIR "Install libraries under an architecture subdirectory" NO)

if(COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
  set(COLLECTIONS_SINGLE_MODULE YES)
endif()

include(CTest)
include(GNUInstallDirs)
include(SwiftSupport)

set(collections_swift_flags
  "-enable-upcoming-feature MemberImportVisibility"
  "-enable-experimental-feature BuiltinModule"
  "-enable-experimental-feature Lifetimes"
  "-enable-experimental-feature InoutLifetimeDependence"
)
foreach(flag ${collections_swift_flags})
 add_compile_options("$<$<COMPILE_LANGUAGE:Swift>:SHELL:${flag}>")
endforeach()

#add_compile_options("$<$<COMPILE_LANGUAGE:Swift>:SHELL:${collections_swift_flags}>")

set(availability_defs
  "SwiftStdlib 5.0: macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2"
  "SwiftStdlib 5.1: macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0"
  "SwiftStdlib 5.6: macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4"
  "SwiftStdlib 5.8: macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4"
  "SwiftStdlib 5.9: macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0"
  "SwiftStdlib 5.10: macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.1"
  "SwiftStdlib 6.0: macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0"
  "SwiftStdlib 6.1: macOS 15.4, iOS 18.4, watchOS 11.4, tvOS 18.4, visionOS 2.4"
  "SwiftStdlib 6.2: macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0"
  )
foreach(def ${availability_defs})
 add_compile_options("$<$<COMPILE_LANGUAGE:Swift>:SHELL:-enable-experimental-feature \"AvailabilityMacro=${def}\">")
endforeach()

add_subdirectory(Sources)
# if(BUILD_TESTING)
#   add_subdirectory(Tests)
# endif()
add_subdirectory(cmake/modules)
