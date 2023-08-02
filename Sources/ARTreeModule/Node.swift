public typealias KeyPart = UInt8
public typealias Key = [KeyPart]

typealias NodeHeaderPtr = UnsafeMutablePointer<NodeHeader>
typealias NodePtr = UnsafeMutableRawPointer
typealias ChildSlotPtr = UnsafeMutablePointer<NodePtr?>

/// Shared protocol implementation for Node types in an Adaptive Radix Tree
protocol Node: NodePrettyPrinter {
  typealias Index = Int

  var pointer: NodePtr { get }
  var count: Int { get set }
  var partialLength: Int { get }
  var partialBytes: PartialBytes { get set }

  func type() -> NodeType

  func index(forKey k: KeyPart) -> Index?
  func index() -> Index?
  func next(index: Index) -> Index?

  func child(forKey k: KeyPart) -> NodePtr?
  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> NodePtr?
  func child(at: Index) -> NodePtr?
  func child(at index: Index, ref: inout ChildSlotPtr?) -> NodePtr?

  mutating func addChild(forKey k: KeyPart, node: NodePtr)
  mutating func addChild(forKey k: KeyPart, node: Node)
  mutating func addChild(
    forKey k: KeyPart,
    node: Node,
    ref: ChildSlotPtr?)
  mutating func addChild(
    forKey k: KeyPart,
    node: NodePtr,
    ref: ChildSlotPtr?)

  // TODO: Shrinking/expand logic can be moved out.
  mutating func deleteChild(forKey k: KeyPart, ref: ChildSlotPtr?)
  mutating func deleteChild(at index: Index, ref: ChildSlotPtr?)
}
