//
//  GithubUserViewController.swift
//  CombinePractice
//
//  Created by Ashraf Uddin on 10/10/21.
//

import UIKit
import Combine

class GithubUserViewController: UIViewController {
    
    @IBOutlet weak var githubIdTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var repositoryCountLabel: UILabel!
    @IBOutlet weak var githubAvatarImageView: UIImageView!
    
    var usernameCounterSubscriber: AnyCancellable?
    var repositoryCounterSubscriber: AnyCancellable?
    var usernameSubcriber: AnyCancellable?
    var headingSubscriber: AnyCancellable?
    var apiNetworkActivitySubscriber: AnyCancellable?
    var avatarViewSubscriber: AnyCancellable?
    
    @Published var username: String = ""
    @Published private var githubUserData: [GithubAPIUser] = []
    
    var myBackgroundQueue: DispatchQueue = DispatchQueue(label: "viewControllerBackgroundQueue")
    //let coreLocationProxy = LocationHeadingProxy()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        githubIdTextField.addTarget(self, action: #selector(githubNameChanged),
                                    for: UIControl.Event.editingChanged)
        activityIndicator.hidesWhenStopped = true
        
        let apiActivitySub = GithubAPI.networkActivityPublisher
            .receive(on: RunLoop.main)
            .sink { doingSomething in
                if (doingSomething) {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
            }
        
        apiNetworkActivitySubscriber = AnyCancellable(apiActivitySub)
        
        usernameSubcriber = $username
            .throttle(for: 0.5, scheduler: myBackgroundQueue, latest: true)
            .removeDuplicates()
            .map{ username -> AnyPublisher<[GithubAPIUser], Never> in
                return GithubAPI.retriveGithubUser(username: username)
            }
            .switchToLatest()
            .assign(to: \.githubUserData, on: self)
        
        repositoryCounterSubscriber = $githubUserData
            .map { userData -> String in
                if let firstUser = userData.first {
                    return String(firstUser.public_repos)
                }
                return "unknown"
            }
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: repositoryCountLabel)
        
        let avatarViewSub = $githubUserData
            .map { userData -> AnyPublisher<UIImage, Never> in
                guard let firstUser = userData.first else {
                    return Just(UIImage()).eraseToAnyPublisher()
                }
                return URLSession.shared.dataTaskPublisher(for: URL(string: firstUser.avatar_url)!)
                    .handleEvents(receiveSubscription: { _ in
                        DispatchQueue.main.async {
                            self.activityIndicator.startAnimating()
                        }
                    }, receiveCompletion: { _ in
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                        }
                    }, receiveCancel: {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                        }
                    })
                    .receive(on: self.myBackgroundQueue)
                    .map{ $0.data }
                    .map { UIImage(data: $0)!}
                    .catch { err in
                        return Just(UIImage())
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .map { image -> UIImage? in
                image
            }
            .assign(to: \.image, on: self.githubAvatarImageView)
        avatarViewSubscriber = AnyCancellable(avatarViewSub)
        

    }
    
    @objc func githubNameChanged() {
          username = githubIdTextField.text ?? ""
          print("Set username to ", username)
      }
}
