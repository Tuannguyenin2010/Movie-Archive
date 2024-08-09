import UIKit
import FirebaseAuth

class CreateAccountViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var togglePasswordVisibilityButton: UIButton!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    private var isPasswordVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        emailErrorLabel.isHidden = true
        passwordErrorLabel.isHidden = true

        setupPasswordVisibilityToggle()
        setupTapGestureToDismissKeyboard()
    }

    private func setupPasswordVisibilityToggle() {
        togglePasswordVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        togglePasswordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        passwordTextField.isSecureTextEntry = true
    }

    private func setupTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        let imageName = isPasswordVisible ? "eye" : "eye.slash"
        togglePasswordVisibilityButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Invalid input")
            return
        }
        if password.count < 6 {
            passwordTextField.layer.borderWidth = 1.0
            passwordTextField.layer.borderColor = UIColor.red.cgColor
            passwordErrorLabel.text = "Password must have 6 or more characters."
            passwordErrorLabel.isHidden = false
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error as NSError? {
                switch error.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    self.emailTextField.layer.borderWidth = 1.0
                    self.emailTextField.layer.borderColor = UIColor.red.cgColor
                    self.emailErrorLabel.text = "This email address is already used!"
                    self.emailErrorLabel.isHidden = false
                case AuthErrorCode.invalidEmail.rawValue:
                    self.emailTextField.layer.borderWidth = 1.0
                    self.emailTextField.layer.borderColor = UIColor.red.cgColor
                    self.emailErrorLabel.text = "Invalid email format!"
                    self.emailErrorLabel.isHidden = false
                default:
                    self.emailTextField.layer.borderWidth = 1.0
                    self.emailTextField.layer.borderColor = UIColor.red.cgColor
                    self.emailErrorLabel.text = "An error occurred. Please try again."
                    self.emailErrorLabel.isHidden = false
                }
                print("Error creating user: \(error.localizedDescription)")
            } else {
                print("User created successfully")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderWidth = 0
        textField.layer.borderColor = UIColor.clear.cgColor
        if textField == emailTextField {
            emailErrorLabel.isHidden = true
        } else if textField == passwordTextField {
            passwordErrorLabel.isHidden = true
        }
    }
}
