//
//  GithubApi.swift
//  CombinePractice
//
//  Created by Ashraf Uddin on 9/10/21.
//

import Foundation
import Combine

enum APIFailureCondition: Error {
    case invalidServerResponse
}

struct GithubAPIUser: Decodable {
    let login: String
    let public_repos: Int
    let avatar_url: String
}

struct GithubAPI {
    
    static let networkActivityPublisher = PassthroughSubject<Bool, Never>()
    
    static func retriveGithubUser(username: String) -> AnyPublisher<[GithubAPIUser], Never> {
        guard username.count > 3, let requestUrl = URL(string: "https://api.github.com/users/\(username)") else {
            return Just([]).eraseToAnyPublisher()
        }
        
       
        let publisher = URLSession.shared.dataTaskPublisher(for: requestUrl)
            .handleEvents { _ in
                networkActivityPublisher.send(true)
            } receiveCompletion: { _ in
                networkActivityPublisher.send(false)
            } receiveCancel: {
                networkActivityPublisher.send(false)
            }
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw APIFailureCondition.invalidServerResponse
                }
                return  data
            }
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
            .map{ [$0] }
            .replaceError(with: [])
            .eraseToAnyPublisher()
        return publisher
    }
}
