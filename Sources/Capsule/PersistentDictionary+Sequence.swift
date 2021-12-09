//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary: Sequence {
    public __consuming func makeIterator() -> DictionaryKeyValueTupleIterator<Key, Value> {
        return DictionaryKeyValueTupleIterator(rootNode: rootNode)
    }
}
