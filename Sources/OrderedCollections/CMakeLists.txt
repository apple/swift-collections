#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(OrderedCollections
  "HashTable/_HashTable.swift"
  "HashTable/_HashTable+Bucket.swift"
  "HashTable/_HashTable+BucketIterator.swift"
  "HashTable/_HashTable+Constants.swift"
  "HashTable/_HashTable+CustomStringConvertible.swift"
  "HashTable/_Hashtable+Header.swift"
  "HashTable/_HashTable+Testing.swift"
  "HashTable/_HashTable+UnsafeHandle.swift"

  "OrderedDictionary/OrderedDictionary.swift"
  "OrderedDictionary/OrderedDictionary+Codable.swift"
  "OrderedDictionary/OrderedDictionary+CustomDebugStringConvertible.swift"
  "OrderedDictionary/OrderedDictionary+CustomReflectable.swift"
  "OrderedDictionary/OrderedDictionary+CustomStringConvertible.swift"
  "OrderedDictionary/OrderedDictionary+Elements+SubSequence.swift"
  "OrderedDictionary/OrderedDictionary+Elements.swift"
  "OrderedDictionary/OrderedDictionary+Equatable.swift"
  "OrderedDictionary/OrderedDictionary+ExpressibleByDictionaryLiteral.swift"
  "OrderedDictionary/OrderedDictionary+Hashable.swift"
  "OrderedDictionary/OrderedDictionary+Initializers.swift"
  "OrderedDictionary/OrderedDictionary+Invariants.swift"
  "OrderedDictionary/OrderedDictionary+Partial MutableCollection.swift"
  "OrderedDictionary/OrderedDictionary+Partial RangeReplaceableCollection.swift"
  "OrderedDictionary/OrderedDictionary+Sequence.swift"
  "OrderedDictionary/OrderedDictionary+Values.swift"
  "OrderedDictionary/OrderedDictionary+Deprecations.swift"

  "OrderedSet/OrderedSet.swift"
  "OrderedSet/OrderedSet+Codable.swift"
  "OrderedSet/OrderedSet+CustomDebugStringConvertible.swift"
  "OrderedSet/OrderedSet+CustomReflectable.swift"
  "OrderedSet/OrderedSet+CustomStringConvertible.swift"
  "OrderedSet/OrderedSet+Diffing.swift"
  "OrderedSet/OrderedSet+Equatable.swift"
  "OrderedSet/OrderedSet+ExpressibleByArrayLiteral.swift"
  "OrderedSet/OrderedSet+Hashable.swift"
  "OrderedSet/OrderedSet+Initializers.swift"
  "OrderedSet/OrderedSet+Insertions.swift"
  "OrderedSet/OrderedSet+Invariants.swift"
  "OrderedSet/OrderedSet+Partial MutableCollection.swift"
  "OrderedSet/OrderedSet+Partial RangeReplaceableCollection.swift"
  "OrderedSet/OrderedSet+Partial SetAlgebra+Basics.swift"
  "OrderedSet/OrderedSet+Partial SetAlgebra+Operations.swift"
  "OrderedSet/OrderedSet+Partial SetAlgebra+Predicates.swift"
  "OrderedSet/OrderedSet+RandomAccessCollection.swift"
  "OrderedSet/OrderedSet+ReserveCapacity.swift"
  "OrderedSet/OrderedSet+SubSequence.swift"
  "OrderedSet/OrderedSet+Testing.swift"
  "OrderedSet/OrderedSet+UnorderedView.swift"
  "OrderedSet/OrderedSet+UnstableInternals.swift"

  "Utilities/_UnsafeBitset.swift"
  "Utilities/RandomAccessCollection+Offsets.swift")
set_target_properties(OrderedCollections PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

_install_target(OrderedCollections)
set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS OrderedCollections)
