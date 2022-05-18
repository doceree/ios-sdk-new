
import Foundation
import Combine

func decode<T: Decodable>(_ data: Data) -> AnyPublisher<T, APIError> {
	let decoder = JSONDecoder()
	decoder.dateDecodingStrategy = .secondsSince1970
    do {
            print(String(data: try
                        JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: data, options: []),
                                               options: .prettyPrinted), encoding: .utf8)!)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Int] {
                debugPrint(json)
            }
        } catch let error as NSError {
            print(data)
            print("Failed to load: \(error.localizedDescription)")
        }
         
	return Just(data)
		.decode(type: T.self, decoder: decoder)
		.mapError { error in
			.parsing(description: error.localizedDescription)
		}
		.eraseToAnyPublisher()
}
