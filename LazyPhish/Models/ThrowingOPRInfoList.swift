@propertyWrapper
struct ThrowingOPRInfoList {
    var wrappedValue: [OPRFailable]
}

extension ThrowingOPRInfoList: Decodable {
    private struct AnyDecodableValue: Decodable {}
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        var elements: [OPRFailable] = []
        while !container.isAtEnd {
            do {
                let value = try container.decode(OPRInfo.self)
                elements.append(value)
            } catch {
                let result = try? container.decode(FailedOPRInfo.self)
                if result != nil {
                    elements.append(result!)
                    continue
                }
                throw error
            }
        }

        self.wrappedValue = elements
    }
}
