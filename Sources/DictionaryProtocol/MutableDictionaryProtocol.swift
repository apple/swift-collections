protocol MutableDictionaryProtocol<Key, Value>: DictionaryProtocol {
    var values: Values { get set }
    var elements: Elements { get set }
    
    mutating func updateValue(_ value: Value, forKey key: Key) -> Value?
    mutating func removeValue(forKey key: Key) -> Value?
}
