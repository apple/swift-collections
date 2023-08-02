typealias PartialBytes = FixedSizedArray8<UInt8>

struct NodeHeader {
  var type: NodeType
  var count: UInt16 = 0  // TODO: Make it smaller. Node256 issue.
  var partialLength: UInt8 = 0
  var partialBytes: PartialBytes = PartialBytes(val: 0)

  init(_ type: NodeType) {
    self.type = type
  }
}
