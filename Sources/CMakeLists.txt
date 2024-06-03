#[[
This source file is part of the Swift Collections Open Source Project

Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_subdirectory(BitCollections)
add_subdirectory(DequeModule)
add_subdirectory(HashTreeCollections)
add_subdirectory(HeapModule)
add_subdirectory(OrderedCollections)
add_subdirectory(RopeModule)
add_subdirectory(InternalCollectionsUtilities)

# Add Collections last so it can find global properties set by sub directories
add_subdirectory(Collections)
