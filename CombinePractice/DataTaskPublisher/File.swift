//
//  File.swift
//  CombinePractice
//
//  Created by Ashraf Uddin on 6/6/21.
//

import Foundation
import Combine

struct  PostmanEchoTimeStampCheckResponse: Decodable, Hashable{
    let valid: Bool
}
enum TestFailureCondition: Error {
    case invalidServerResponse
}

enum APIError: Error, LocalizedError {
    case unknown
    case apiError(reason: String)
    case parserError(reason: String)
    case networkError(from: URLError)
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .apiError(let reason), .parserError(let reason):
            return reason
        case .networkError(let from):
            return from.localizedDescription
        }
    }
}

class DataService {
    static let shared = DataService()
    
    let myURL = URL(string: "https://postman-echo.com/time/valid?timestamp=2016-10-10")
    
    func fetch(with url: URL) -> AnyPublisher<PostmanEchoTimeStampCheckResponse, APIError> {
        let request = URLRequest(url: url)
        return URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                if (httpResponse.statusCode == 401) {
                    throw APIError.apiError(reason: "Unauthorized");
                }
                if (httpResponse.statusCode == 403) {
                    throw APIError.apiError(reason: "Resource forbidden");
                }
                if (httpResponse.statusCode == 404) {
                    throw APIError.apiError(reason: "Resource not found");
                }
                if (405..<500 ~= httpResponse.statusCode) {
                    throw APIError.apiError(reason: "client error");
                }
                if (500..<600 ~= httpResponse.statusCode) {
                    throw APIError.apiError(reason: "server error");
                }
                return try JSONDecoder().decode(PostmanEchoTimeStampCheckResponse.self, from: data)
            }
            .mapError { error  in
                if let error = error as? APIError {
                    return error
                }
                if let urlerror = error as? URLError {
                    return APIError.networkError(from: urlerror)
                }
                return APIError.unknown
            }
            .eraseToAnyPublisher()
    }
}
