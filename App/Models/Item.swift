import Foundation

class ItemDao : Codable {
    var item: Item
    
    init (item: Item){
        self.item = item
    }
    
    convenience init?(json: String) {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            let item = try JSONDecoder().decode(ItemDao.self, from: data)
            self.init(item: item.item)
        } catch {
            print ("ItemDao Error Init: \(error)")
            return nil
        }
    }
}

class Item : Codable, Identifiable {
    var id: String
    var isComplete: Bool = false
    var summary: String
    var ownerId: String
    
    init(id: String = UUID().uuidString.lowercased(),
         isComplete: Bool = false,
         summary: String,
         ownerId: String) {
        self.id = id
        self.isComplete = isComplete
        self.summary = summary
        self.ownerId = ownerId
    }

    // Initialize from JSON string
    convenience init?(json: String) {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            let item = try JSONDecoder().decode(Item.self, from: data)
            self.init(id: item.id, isComplete: item.isComplete, summary: item.summary, ownerId: item.ownerId)
        } catch {
            return nil
        }
    }
    
    // Custom decoding initializer
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        // Provide a default value for isComplete if it is missing
        self.isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
    }
    
    // Encoding function (no change needed)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(isComplete, forKey: .isComplete)
        try container.encode(summary, forKey: .summary)
        try container.encode(ownerId, forKey: .ownerId)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case isComplete
        case summary
        case ownerId
    }
    
    // Serialize to JSON string
    func toJSON() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
