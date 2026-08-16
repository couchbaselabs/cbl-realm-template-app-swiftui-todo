import CouchbaseLiteSwift
import Foundation

/// A single to-do task.
///
/// `Codable` conformance is synthesized by the compiler. The property names match
/// the column aliases selected by the queries in `DatabaseService`, so no
/// `CodingKeys` mapping is required.
class Item: Codable, Identifiable {

    /// Bound to the document's *metadata* ID rather than to a field in the document
    /// body, via the `@DocumentID` property wrapper.
    ///
    /// This is `nil` for an item that has not been saved yet; Couchbase Lite assigns
    /// an ID on save. When an item is decoded from a query result, the value comes
    /// from the `meta().id AS id` column — which is why that column must be present
    /// in every query that produces an `Item`.
    @DocumentID var id: String?

    /// Optional so that a document written without this field still decodes,
    /// rather than failing the whole row.
    var isComplete: Bool?

    var summary: String
    var ownerId: String

    init(id: String? = nil,
         isComplete: Bool? = false,
         summary: String,
         ownerId: String) {
        self.id = id
        self.isComplete = isComplete
        self.summary = summary
        self.ownerId = ownerId
    }
}
