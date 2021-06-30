//
//  AsyncCoordinatorViewController.swift
//  CombinePractice
//
//  Created by Ashraf Uddin on 30/6/21.
//

import UIKit
import Combine

class AsyncCoordinatorViewController: UIViewController {
    
    @IBOutlet weak var step1_button: UIButton!
    @IBOutlet weak var step2_1_button: UIButton!
    @IBOutlet weak var step2_2_button: UIButton!
    @IBOutlet weak var step2_3_button: UIButton!
    @IBOutlet weak var step3_button: UIButton!
    @IBOutlet weak var step4_button: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var startButton: UIButton!
    
    var cancellable: AnyCancellable?
    var coordinatedPipeline: AnyPublisher<Bool, Error>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.stopAnimating()
        coordinatedPipeline = createFuturePublisher(button: self.step1_button)
            .flatMap({ flatmapValue -> AnyPublisher<Bool, Error> in
                let step2_1 = self.createFuturePublisher(button: self.step2_1_button)
                let step2_2 = self.createFuturePublisher(button: self.step2_2_button)
                let step2_3 = self.createFuturePublisher(button: self.step2_3_button)
                return Publishers.Zip3(step2_1, step2_2, step2_3)
                    .map { _ -> Bool in
                        return true
                    }
                    .eraseToAnyPublisher()
            })
            .flatMap({ _ in
                return self.createFuturePublisher(button: self.step3_button)
            })
            .flatMap({ _ in
                return self.createFuturePublisher(button: self.step4_button)
            })
            .eraseToAnyPublisher()
    }
    
    
    @IBAction func pressedStart(_ sender: Any) {
        runAllSteps()
    }
    
    func randomAsyncAPI(completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            sleep(.random(in: 1...4))
            completionBlock(true, nil)
        }
    }
    
    func runAllSteps() {
        if self.cancellable != nil {
            cancellable?.cancel()
            self.activityIndicator.stopAnimating()
        }
        
        self.resetAllSteps()
        self.activityIndicator.startAnimating()
        self.cancellable = coordinatedPipeline?
            .print()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion: ", String(describing: completion))
                self.activityIndicator.stopAnimating()
            }, receiveValue: { value in
                print(".sink() received value: ", value)
            })
    }
    
    
    func createFuturePublisher(button: UIButton) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.randomAsyncAPI { (result, error) in
                if let err = error {
                    promise(.failure(err))
                } else {
                    promise(.success(result))
                }
            }
        }
        .receive(on: RunLoop.main)
        .map { value -> Bool in
            self.markStepDone(button: button)
            return true
            
        }
        .eraseToAnyPublisher()
    }
    
    func resetAllSteps() {
        [step1_button, step2_1_button, step2_2_button, step2_3_button, step3_button, step4_button].forEach {
            $0?.backgroundColor = .lightGray
            $0?.isHighlighted = false
        }
    }
    
    func markStepDone(button: UIButton) {
        button.backgroundColor = .systemGreen
        button.isHighlighted = true
    }
}
