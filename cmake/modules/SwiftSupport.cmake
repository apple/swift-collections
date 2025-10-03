#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]


if(NOT COLLECTIONS_MODULE_TRIPLE OR NOT COLLECTIONS_ARCH OR NOT COLLECTIONS_PLATFORM)
  # Get the target information from the Swift compiler.
  set(module_triple_command "${CMAKE_Swift_COMPILER}" -print-target-info)
  if(CMAKE_Swift_COMPILER_TARGET)
    list(APPEND module_triple_command -target ${CMAKE_Swift_COMPILER_TARGET})
  endif()
  execute_process(COMMAND ${module_triple_command} OUTPUT_VARIABLE target_info_json)
endif()

if(NOT COLLECTIONS_MODULE_TRIPLE)
  string(JSON module_triple GET "${target_info_json}" "target" "moduleTriple")
  set(COLLECTIONS_MODULE_TRIPLE "${module_triple}" CACHE STRING "Triple used to install swiftmodule files")
  mark_as_advanced(COLLECTIONS_MODULE_TRIPLE)
  message(CONFIGURE_LOG "Swift module triple: ${module_triple}")
endif()

if(NOT COLLECTIONS_ARCH)
  if(CMAKE_Swift_COMPILER_VERSION VERSION_EQUAL 0.0.0 OR CMAKE_Swift_COMPILER_VERSION VERSION_GREATER_EQUAL 6.2)
    # For newer compilers, we can use the -print-target-info command to get the architecture.
    string(JSON module_arch GET "${target_info_json}" "target" "arch")
  else()
    # For older compilers, extract the value from `COLLECTIONS_MODULE_TRIPLE`.
    string(REGEX MATCH "^[^-]+" module_arch "${COLLECTIONS_MODULE_TRIPLE}")
  endif()

  set(COLLECTIONS_ARCH "${module_arch}" CACHE STRING "Arch folder name used to install libraries")
  mark_as_advanced(COLLECTIONS_ARCH)
  message(CONFIGURE_LOG "Swift arch: ${COLLECTIONS_ARCH}")
endif()

if(NOT COLLECTIONS_PLATFORM)
  if(CMAKE_Swift_COMPILER_VERSION VERSION_EQUAL 0.0.0 OR CMAKE_Swift_COMPILER_VERSION VERSION_GREATER_EQUAL 6.2)
    # For newer compilers, we can use the -print-target-info command to get the platform.
    string(JSON swift_platform GET "${target_info_json}" "target" "platform")
  else()
    # For older compilers, compile the value from `CMAKE_SYSTEM_NAME`.
    if(APPLE)
      set(swift_platform macosx)
    else()
      set(swift_platform "$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>")
    endif()
  endif()

  set(COLLECTIONS_PLATFORM "${swift_platform}" CACHE STRING "Platform folder name used to install libraries")
  mark_as_advanced(COLLECTIONS_PLATFORM)
  message(CONFIGURE_LOG "Swift platform: ${COLLECTIONS_PLATFORM}")
endif()

function(_install_target module)
  get_target_property(type ${module} TYPE)

  if(type STREQUAL STATIC_LIBRARY)
    set(swift swift_static)
  else()
    set(swift swift)
  endif()

  install(TARGETS ${module}
    ARCHIVE DESTINATION lib/${swift}/${COLLECTIONS_PLATFORM}$<$<BOOL:${COLLECTIONS_INSTALL_ARCH_SUBDIR}>:/${COLLECTIONS_ARCH}>
    LIBRARY DESTINATION lib/${swift}/${COLLECTIONS_PLATFORM}$<$<BOOL:${COLLECTIONS_INSTALL_ARCH_SUBDIR}>:/${COLLECTIONS_ARCH}>
    RUNTIME DESTINATION bin)
  if(type STREQUAL EXECUTABLE)
    return()
  endif()

  get_target_property(module_name ${module} Swift_MODULE_NAME)
  if(NOT module_name)
    set(module_name ${module})
  endif()

  install(FILES $<TARGET_PROPERTY:${module},Swift_MODULE_DIRECTORY>/${module_name}.swiftdoc
    DESTINATION lib/${swift}/${COLLECTIONS_PLATFORM}/${module_name}.swiftmodule
    RENAME ${COLLECTIONS_MODULE_TRIPLE}.swiftdoc)

  install(FILES $<TARGET_PROPERTY:${module},Swift_MODULE_DIRECTORY>/${module_name}.swiftmodule
    DESTINATION lib/${swift}/${COLLECTIONS_PLATFORM}/${module_name}.swiftmodule
    RENAME ${COLLECTIONS_MODULE_TRIPLE}.swiftmodule)
endfunction()

# Makes <exported> importable by any target listing <exporter> in its
# target_link_libraries.
function(swift_module_re_exports exporter exported)
  set(swift_module_directory "$<TARGET_PROPERTY:${exported},Swift_MODULE_DIRECTORY>")
  set(binary_directory "$<TARGET_PROPERTY:${exported},BINARY_DIR>")
  set_property(TARGET ${exporter}
    APPEND
    PROPERTY INTERFACE_INCLUDE_DIRECTORIES
  "$<IF:$<STREQUAL:${swift_module_directory},>,${binary_directory},${swift_module_directory}>")
endfunction()
