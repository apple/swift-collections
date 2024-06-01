public protocol DictionaryProtocol<Key, Value>: Sequence, ExpressibleByDictionaryLiteral where Element == (key: Key, value: Value), Key: Hashable {
    associatedtype Key
    associatedtype Value
    
    associatedtype Keys: Collection where Keys.Element == Key
    associatedtype Values: Collection where Values.Element == Value
    associatedtype Elements: Collection where Elements.Element == Element
    
    var keys: Keys { get }
    var values: Values { get }
    var elements: Elements { get }
        
    subscript(key: Key) -> Value? { get }
    
    init()
    
    // Cannot implement since stdlib's Dictionary has a different signature (unlabelled tuple)
    //init<S: Sequence>(uniqueKeysWithValues keysAndValues: S) where S.Element == (key: Key, value: Value)
    
    init<S: Sequence>(uniqueKeysWithValues keysAndValues: S) where S.Element == (Key, Value)
    
    init<S: Sequence>(
        _ keysAndValues: S,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows where S.Element == (Key, Value)
    
    // OrderedDictionary also has a more generic version of this with the where clause: `where Value: RangeReplaceableCollection, Value.Element == S.Element` instead of `Value == [S.Element]`
    init<S: Sequence>(
        grouping values: S,
        by keyForValue: (S.Element) throws -> Key
    ) rethrows where Value == [S.Element]

    init(_ other: some DictionaryProtocol<Key, Value>)
    
    // does not work for stdlib Dictionary. Not sure how to capture stdlib Dictionary signature for this method in protocol
    //func mapValues<T, Result: DictionaryProtocol>(_ transform: (Value) throws -> T) rethrows -> Result where Result.Value == T
    // func compactMapValues<T> // same as above
    
    func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> Self
}

extension DictionaryProtocol {
    // This does not guarantee any sort of ordering when using `OrderedDictionary` however...
    public init(_ other: some DictionaryProtocol<Key, Value>) {
        // .lazy.map in order to remove labels from tuple
        self.init(uniqueKeysWithValues: other.elements.lazy.map { $0 })
    }
}
