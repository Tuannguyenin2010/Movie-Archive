import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var passwordTextField: UITextField!
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

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Invalid input")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error as NSError? {
                print("Error signing in: \(error.localizedDescription)")
                self.handleLoginError(error)
            } else {
                print("User signed in successfully")
                self.navigateToMainScreen()
            }
        }
    }

    func handleLoginError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.userNotFound.rawValue:
            self.emailTextField.layer.borderWidth = 1.0
            self.emailTextField.layer.borderColor = UIColor.red.cgColor
            self.emailErrorLabel.text = "This account doesn't exist!"
            self.emailErrorLabel.isHidden = false
        case AuthErrorCode.wrongPassword.rawValue:
            self.passwordTextField.layer.borderWidth = 1.0
            self.passwordTextField.layer.borderColor = UIColor.red.cgColor
            self.passwordErrorLabel.text = "Incorrect password!"
            self.passwordErrorLabel.isHidden = false
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
            print("Error signing in: \(error.localizedDescription)")
        }
    }

    func navigateToMainScreen() {
        // Perform segue to MainViewController
        performSegue(withIdentifier: "showMain", sender: self)
    }

    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        // Perform segue to CreateAccountViewController
        performSegue(withIdentifier: "showCreateAccount", sender: self)
    }

    // Ensure to reset text fields and hide error labels when editing begins
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
