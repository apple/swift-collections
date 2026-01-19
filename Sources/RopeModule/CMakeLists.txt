#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE)
  set(module_name ${COLLECTIONS_MODULE_NAME})
else()
  set(module_name _RopeModule)
  add_library(_RopeModule
    ${COLLECTIONS_ROPE_SOURCES})
  target_link_libraries(_RopeModule PUBLIC
    InternalCollectionsUtilities)

  _install_target(_RopeModule)
  set_property(GLOBAL APPEND PROPERTY SWIFT_COLLECTIONS_EXPORTS _RopeModule)
  
  # Re-export InternalCollectionsUtilities so dependents can access it
  swift_module_re_exports(_RopeModule InternalCollectionsUtilities)
endif()

target_sources(${module_name} PRIVATE
  "BigString/Basics/BigString.swift"
  "BigString/Basics/BigString+Builder.swift"
  "BigString/Basics/BigString+Contents.swift"
  "BigString/Basics/BigString+Debugging.swift"
  "BigString/Basics/BigString+Index.swift"
  "BigString/Basics/BigString+Ingester.swift"
  "BigString/Basics/BigString+Invariants.swift"
  "BigString/Basics/BigString+Metrics.swift"
  "BigString/Basics/BigString+Summary.swift"
  "BigString/Chunk/BigString+Chunk.swift"
  "BigString/Chunk/BigString+Chunk+Append and Insert.swift"
  "BigString/Chunk/BigString+Chunk+Breaks.swift"
  "BigString/Chunk/BigString+Chunk+Character.swift"
  "BigString/Chunk/BigString+Chunk+Counts.swift"
  "BigString/Chunk/BigString+Chunk+Description.swift"
  "BigString/Chunk/BigString+Chunk+Index.swift"
  "BigString/Chunk/BigString+Chunk+RopeElement.swift"
  "BigString/Chunk/BigString+Chunk+Splitting.swift"
  "BigString/Chunk/BigString+Chunk+UnicodeScalar.swift"
  "BigString/Chunk/BigString+Chunk+UTF16.swift"
  "BigString/Chunk/BigString+Chunk+UTF8.swift"
  "BigString/Conformances/BigString+BidirectionalCollection.swift"
  "BigString/Conformances/BigString+Comparable.swift"
  "BigString/Conformances/BigString+CustomDebugStringConvertible.swift"
  "BigString/Conformances/BigString+CustomStringConvertible.swift"
  "BigString/Conformances/BigString+Equatable.swift"
  "BigString/Conformances/BigString+ExpressibleByStringLiteral.swift"
  "BigString/Conformances/BigString+Hashing.swift"
  "BigString/Conformances/BigString+LosslessStringConvertible.swift"
  "BigString/Conformances/BigString+RangeReplaceableCollection.swift"
  "BigString/Conformances/BigString+Sequence.swift"
  "BigString/Conformances/BigString+TextOutputStream.swift"
  "BigString/Operations/BigString+Append.swift"
  "BigString/Operations/BigString+Initializers.swift"
  "BigString/Operations/BigString+Insert.swift"
  "BigString/Operations/BigString+Managing Breaks.swift"
  "BigString/Operations/BigString+RemoveSubrange.swift"
  "BigString/Operations/BigString+ReplaceSubrange.swift"
  "BigString/Operations/BigString+Split.swift"
  "BigString/Operations/Range+BigString.swift"
  "BigString/Views/BigString+UnicodeScalarView.swift"
  "BigString/Views/BigString+UTF16View.swift"
  "BigString/Views/BigString+UTF8View.swift"
  "BigString/Views/BigSubstring.swift"
  "BigString/Views/BigSubstring+UnicodeScalarView.swift"
  "BigString/Views/BigSubstring+UTF16View.swift"
  "BigString/Views/BigSubstring+UTF8View.swift"
  "Rope/Basics/_RopeItem.swift"
  "Rope/Basics/_RopePath.swift"
  "Rope/Basics/_RopeVersion.swift"
  "Rope/Basics/Rope.swift"
  "Rope/Basics/Rope+_Node.swift"
  "Rope/Basics/Rope+_Storage.swift"
  "Rope/Basics/Rope+_UnmanagedLeaf.swift"
  "Rope/Basics/Rope+_UnsafeHandle.swift"
  "Rope/Basics/Rope+Builder.swift"
  "Rope/Basics/Rope+Debugging.swift"
  "Rope/Basics/Rope+Invariants.swift"
  "Rope/Basics/RopeElement.swift"
  "Rope/Basics/RopeMetric.swift"
  "Rope/Basics/RopeSummary.swift"
  "Rope/Conformances/Rope+Collection.swift"
  "Rope/Conformances/Rope+Index.swift"
  "Rope/Conformances/Rope+Sequence.swift"
  "Rope/Operations/Rope+Append.swift"
  "Rope/Operations/Rope+Extract.swift"
  "Rope/Operations/Rope+Find.swift"
  "Rope/Operations/Rope+ForEachWhile.swift"
  "Rope/Operations/Rope+Insert.swift"
  "Rope/Operations/Rope+Join.swift"
  "Rope/Operations/Rope+MutatingForEach.swift"
  "Rope/Operations/Rope+Remove.swift"
  "Rope/Operations/Rope+RemoveSubrange.swift"
  "Rope/Operations/Rope+Split.swift"
  "Utilities/Optional Utilities.swift"
  "Utilities/String Utilities.swift"
  "Utilities/String.Index+ABI.swift"
  "Utilities/_CharacterRecognizer.swift"
  )
