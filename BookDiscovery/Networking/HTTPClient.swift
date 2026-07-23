import Foundation

protocol HTTPClient {
    func send<Response: Decodable>(_ request: URLRequest) async throws -> Response
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard 200..<300 ~= httpResponse.statusCode else {
                throw NetworkError.httpStatus(code: httpResponse.statusCode)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw NetworkError.decoding(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw NetworkError.transport(error)
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(code: Int)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "The request URL could not be created."
        case .invalidResponse: "The server returned an invalid response."
        case .httpStatus(let code): "The server returned HTTP status \(code)."
        case .transport(let error): "The request failed: \(error.localizedDescription)"
        case .decoding: "The book data could not be read."
        }
    }
}
