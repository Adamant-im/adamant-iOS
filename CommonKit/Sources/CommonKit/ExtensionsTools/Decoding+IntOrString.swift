import Foundation

extension KeyedDecodingContainer {
    func decodeIntOrString(forKey key: Key) throws -> Int? {
        if let intVal = try? self.decode(Int.self, forKey: key) {
            return intVal
        }
        if let strVal = try? self.decode(String.self, forKey: key) {
            return Int(strVal)
        }
        if let doubleVal = try? self.decode(Double.self, forKey: key) {
            return Int(doubleVal)
        }
        return nil
    }
}
