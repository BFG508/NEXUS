import Foundation

public enum ManifestDecoder {
    private struct SchemaProbe: Decodable {
        let schema: String
    }

    public static func decode(_ data: Data) throws -> RunManifest {
        let decoder = ISO8601Coding.makeDecoder()
        do {
            let probe = try decoder.decode(SchemaProbe.self, from: data)
            guard probe.schema == ATLASContract.supportedManifestSchema else {
                throw ATLASDecodingError.unsupportedSchema(probe.schema)
            }
            return try ISO8601Coding.makeDecoder().decode(RunManifest.self, from: data)
        } catch let error as ATLASDecodingError {
            throw error
        } catch {
            throw ATLASDecodingError.malformedManifest(error.localizedDescription)
        }
    }
}
