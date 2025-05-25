import Foundation

func fromJSON<T: Codable>(_ jsonDict: [String: Any], to type: T.Type) throws -> T {
    // Convert dictionary to Data
    let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
    
    // Decode to target type
    let decoder = JSONDecoder()
    return try decoder.decode(type, from: jsonData)
}

func toJSON<T: Codable>(_ object: T) throws -> Any {
    // Encode object to Data
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(object)
    
    // Convert Data to JSON
    let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: [])
    return jsonDict
}
