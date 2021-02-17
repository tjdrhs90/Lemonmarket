import UIKit
import Toast_Swift
import FirebaseAuth
import FirebaseDatabase

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    let fullAddress:NSString = ""
    let simpleAddress:NSString = ""
    
    let date = NSDate()
    let formatter = DateFormatter()
    
    let alertController = UIAlertController(title: nil, message: "가입중입니다.\n\n\n", preferredStyle: .alert)
    let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    var ref: DatabaseReference!
    
    @IBOutlet var idTxtField: UITextField!
    @IBOutlet var pwTxtField: UITextField!
    @IBOutlet var pwTxtField2: UITextField!
    @IBOutlet var usernameTxtField: UITextField!
    
    @IBOutlet var idCheckLabel: UILabel!
    @IBOutlet var pwCheckLabel: UILabel!
    @IBOutlet var pwCheckLabel2: UILabel!
    @IBOutlet var usernameCheckLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.lightGray
        spinnerIndicator.startAnimating()
        
        alertController.view.addSubview(spinnerIndicator)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
        
        ref = Database.database().reference() //최상위 가져오기       
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm EEE"
    }
     
    @IBAction func didSignUpButtonTapped(_ sender: Any) {
        
        self.present(alertController, animated: true, completion: nil)
        
        SignUp()
        endEditing()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        if textField == idTxtField {
            if validateEmail(candidate: idTxtField.text!) {
                idCheckLabel.text = ""
            } else if idTxtField.text != "" {
                idCheckLabel.text = "이메일 형식이 아닙니다."
            }
        }
        if textField == pwTxtField {
            if pwTxtField.text!.count < 6 && pwTxtField.text! != "" {
                pwCheckLabel.text = "비밀번호가 6자리 미만입니다."
            } else if pwTxtField2.text != "" && pwTxtField.text != pwTxtField2.text{
                pwCheckLabel.text = "비밀번호가 일치하지 않습니다."
                pwCheckLabel2.text = "비밀번호가 일치하지 않습니다."
            } else if pwTxtField.text != "" {
                pwCheckLabel.text = ""
                pwCheckLabel2.text = ""
            }
        }
        if textField == pwTxtField2 {
            if pwTxtField.text == pwTxtField2.text {
                pwCheckLabel2.text = ""
            } else if pwTxtField2.text != "" && pwTxtField.text != "" {
                pwCheckLabel.text = "비밀번호가 일치하지 않습니다."
                pwCheckLabel2.text = "비밀번호가 일치하지 않습니다."
            }
            if pwTxtField.text == pwTxtField2.text && pwTxtField.text!.count > 5 && pwTxtField2.text!.count > 5 {
                pwCheckLabel.text = ""
                pwCheckLabel2.text = ""
            }
        }
        if textField == usernameTxtField {
            if usernameTxtField.text != "" && usernameTxtField.text!.trimmingCharacters(in: .whitespaces).isEmpty {
                usernameCheckLabel.text = "닉네임을 입력하세요."
            } else {
                usernameCheckLabel.text = ""
            }
        }
    }
    
    func SignUp() {
        if idTxtField.text == "" ||
            pwTxtField.text == "" ||
            pwTxtField2.text == "" ||
            usernameTxtField.text == "" ||
            idCheckLabel.text != "" ||
            pwCheckLabel.text != "" ||
            pwCheckLabel2.text != "" ||
            usernameCheckLabel.text != "" {
            
            self.view.makeToast("입력사항을 확인하세요.")
            
            alertController.dismiss(animated: true)
            return
        }
        
        Auth.auth().createUser(withEmail: idTxtField.text!, password: pwTxtField.text!
            
        ) { (user, error) in
            
            if user !=  nil{
                // TODO: 회원가입 정상 처리 후 다음 로직, 로그인 페이지 or 바로 로그인 시키기
                print("register success")
                
                let user = Auth.auth().currentUser //currentUser가 nil이면 로그인안된것
                
                self.ref.child("users/\(user!.uid)").setValue(["uid": user?.uid,
                                                               "email": user?.email,
                                                               "username": self.usernameTxtField.text,
                                                               "password": self.pwTxtField.text,
                                                               "fullAddress": self.fullAddress,
                                                               "simpleAddress": self.simpleAddress,
                                                               "time":self.formatter.string(from: self.date as Date)])
                let storyboard: UIStoryboard = self.storyboard!
                let TabVC: UITabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                TabVC.view.makeToast("가입되었습니다.")
                self.alertController.dismiss(animated: true)
                self.navigationController?.pushViewController(TabVC, animated: true)
            }
            else{
                // TODO: 회원가입 실패
                self.view.makeToast("존재하는 계정입니다.")
                self.alertController.dismiss(animated: true)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case idTxtField:
            pwTxtField.becomeFirstResponder()
        case pwTxtField:
            pwTxtField2.becomeFirstResponder()
        case pwTxtField2:
            usernameTxtField.becomeFirstResponder()
        default:
            usernameTxtField.resignFirstResponder()
            SignUp()
        }
        return true
    }
    
    //이메일형식 체크
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
    
    @objc func endEditing(){
        idTxtField.resignFirstResponder()
        pwTxtField.resignFirstResponder()
        pwTxtField2.resignFirstResponder()
        usernameTxtField.resignFirstResponder()
    }
    
}

