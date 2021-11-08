//
//  InputFormViewController.swift
//  CombinePractice
//
//  Created by Ashraf Uddin on 8/11/21.
//

import UIKit
import Combine

class InputFormViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var usernameMessagelabel: UILabel!
    @IBOutlet weak var passwordMessageLabel: UILabel!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    var validatedUsername: AnyPublisher<String?, Never> {
        return $username.map { username in
            guard username.count > 2 else {
                DispatchQueue.main.async {
                    self.usernameMessagelabel.text = "Username must be three chracters long"
                }
                return nil
            }
            DispatchQueue.main.async {
                self.usernameMessagelabel.text = ""
            }
            return username
        }.eraseToAnyPublisher()
    }
    
    var validatedPassword: AnyPublisher<String?, Never> {
        return Publishers.CombineLatest($password, $confirmPassword)
            .receive(on: RunLoop.main)
            .map { password, confirmPassword in
                guard password == confirmPassword, password.count > 5 else {
                    self.passwordMessageLabel.text = "values must match and have at least 6 characters"
                    return nil
                }
                self.passwordMessageLabel.text = ""
                return password
            }.eraseToAnyPublisher()
    }
    
    var readyToSubmit: AnyPublisher<(String, String)?, Never> {
        return Publishers.CombineLatest(validatedUsername, validatedPassword)
            .map { (validatedUsername, validatedPassword) in
                guard let username = validatedUsername, let password = validatedPassword else {
                    return nil
                }
                return (username, password)
            }.eraseToAnyPublisher()
    }
    
    private var cancellableSet: Set<AnyCancellable> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [usernameTextField, passwordTextField, confirmPasswordTextField].forEach {
            $0?.delegate = self
        }
        usernameTextField.addTarget(self, action: #selector(usernameTextFieldDidChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldDidChanged), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(confirmPasswordTextFieldDidChanged), for: .editingChanged)
        
        self.readyToSubmit
            .map { $0 != nil }
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: submitButton)
            .store(in: &cancellableSet)
    }
    
    @objc func usernameTextFieldDidChanged() {
        username = usernameTextField.text ?? ""
    }
    
    @objc func passwordTextFieldDidChanged() {
        password = passwordTextField.text ?? ""
    }
    
    @objc func confirmPasswordTextFieldDidChanged() {
        confirmPassword = confirmPasswordTextField.text ?? ""
    }
}
