import Foundation

enum OpenLibraryEndpoint {
    case search(query: String, page: Int, limit: Int)
    case work(id: String)

    func request(configuration: OpenLibraryConfiguration) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.apiBaseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else { throw NetworkError.invalidURL }

        components.queryItems = queryItems
        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private var path: String {
        switch self {
        case .search: "search.json"
        case .work(let id): "works/\(id).json"
        }
    }

    private var queryItems: [URLQueryItem]? {
        switch self {
        case let .search(query, page, limit):
            [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,first_publish_year,edition_count,subject"),
                URLQueryItem(name: "page", value: String(max(1, page))),
                URLQueryItem(name: "limit", value: String(min(max(1, limit), 100))),
                URLQueryItem(name: "lang", value: "en")
            ]
        case .work:
            nil
        }
    }
}
