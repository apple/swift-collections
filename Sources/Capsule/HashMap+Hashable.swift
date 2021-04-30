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

// TODO settle on (commutative) hash semantics that is reconcilable with `cachedKeySetHashCode`
extension HashMap : Hashable where Value : Hashable {
    public func hash(into hasher: inout Hasher) {
        var commutativeHash = 0
        for (k, v) in self {
            var elementHasher = Hasher()
            elementHasher.combine(k)
            elementHasher.combine(v)
            commutativeHash ^= elementHasher.finalize()
        }
        hasher.combine(commutativeHash)
    }
}
