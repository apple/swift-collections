#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(DequeModule
  _DequeBuffer.swift
  _DequeBufferHeader.swift
  _DequeSlot.swift
  _UnsafeWrappedBuffer.swift
  Compatibility.swift
  Deque._Storage.swift
  Deque._UnsafeHandle.swift
  Deque.swift
  Deque+Codable.swift
  Deque+Collection.swift
  Deque+CustomDebugStringConvertible.swift
  Deque+CustomReflectable.swift
  Deque+CustomStringConvertible.swift
  Deque+Equatable.swift
  Deque+ExpressibleByArrayLiteral.swift
  Deque+Extras.swift
  Deque+Hashable.swift
  Deque+Testing.swift
  UnsafeMutableBufferPointer+Utilities.swift)
set_target_properties(DequeModule PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(DequeModule)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS DequeModule)
