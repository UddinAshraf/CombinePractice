//
//  InputValidationViewController.swift
//  CombinePractice
//
//  Created by Ashraf Uddin on 31/5/21.
//

import UIKit
import Combine

class InputValidationViewController: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var userNameMessageLabel: UILabel!
    @IBOutlet weak var passwordMessageLabel: UILabel!
    
    
    @Published var userName: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    private var cancellableSet: Set<AnyCancellable> = []
    
    var validatedUserName: AnyPublisher<String?, Never> {
        return $userName.map { username in
            guard username.count > 4 else {
                DispatchQueue.main.async {
                    self.userNameMessageLabel.text = "User name must 5 characters long"
                }
                return nil
            }
            DispatchQueue.main.async {
                self.userNameMessageLabel.text = ""
            }
            return username
        }.eraseToAnyPublisher()
    }
    
    var validatedPassword: AnyPublisher<String?, Never> {
        return Publishers.CombineLatest($password, $confirmPassword)
            .receive(on: RunLoop.main)
            .map { password, confirmPassword in
                guard confirmPassword == password, password.count > 4 else {
                    self.passwordMessageLabel.text = "Password must match and have at least 5 characters"
                    return nil
                }
                self.passwordMessageLabel.text = ""
                return password
            }.eraseToAnyPublisher()
    }
    
    var readyToSubmit: AnyPublisher<(String, String)?, Never> {
        return Publishers.CombineLatest(validatedUserName, validatedPassword)
            .map { validatedUserName, validatedPassword in
                guard let validUserName = validatedUserName, let validPassword = validatedPassword else {
                    return nil
                }
                return (validUserName, validPassword)
            }.eraseToAnyPublisher()
    }
    
    
    //MARK: Action methods
    @objc func userNameDidChanged() {
        userName = userNameTextField.text ?? ""
    }
    
    @objc func passwordDidChanged() {
        password = passwordTextField.text ?? ""
    }
    
    @objc func confirmPasswordDidChanged() {
        confirmPassword = confirmPasswordTextField.text ?? ""
    }
    
    @IBAction func submitButtonPressed() {
        let alert = UIAlertController(title: "Valid!!", message: "Values are ready to submit", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitButton.backgroundColor = .lightGray
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10.0
        submitButton.isEnabled = false
        
        userNameTextField.addTarget(self, action: #selector(userNameDidChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordDidChanged), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(confirmPasswordDidChanged), for: .editingChanged)
        
        self.readyToSubmit
            .map { values in
                DispatchQueue.main.async {
                    self.submitButton.backgroundColor = values != nil ? .green : .lightGray
                }
                return values != nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: submitButton)
            .store(in: &cancellableSet)
    }
}
