import UIKit
import FirebaseAuth
import Toast_Swift
import FirebaseDatabase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var ref = Database.database().reference()
    
    var myFlag: Bool = false
    
    @IBOutlet var idTxtField: UITextField!
    @IBOutlet var pwTxtField: UITextField!
    
    let alertController = UIAlertController(title: nil, message: "로그인중입니다.\n\n\n", preferredStyle: .alert)
    let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.lightGray
        spinnerIndicator.startAnimating()
        
        alertController.view.addSubview(spinnerIndicator)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 로그아웃
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("logout")
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
        
    
    
    @IBAction func btnLogin(_ sender: UIButton) {
        
        self.present(alertController, animated: true, completion: nil)
                
        endEditing()
        login()
    }
    
    // touch screen
    @objc func endEditing(){
        idTxtField.resignFirstResponder()
        pwTxtField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == idTxtField {
            pwTxtField.becomeFirstResponder()
        } else {
            pwTxtField.resignFirstResponder()
            login()
        }
        return true
    }
    
    func login() {
        Auth.auth().signIn(withEmail: idTxtField.text!, password: pwTxtField.text!) { (user, error) in
            
            if user != nil{
                // TODO: 로그인 성공 user 객체에서 정보 사용
                let uid: String = Auth.auth().currentUser!.uid
                self.ref.child("users/\(uid)").updateChildValues(["password": self.pwTxtField.text!])
                let storyboard: UIStoryboard = self.storyboard!
                let TabVC: UITabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                TabVC.view.makeToast("로그인 되었습니다.")
                self.alertController.dismiss(animated: true)
                self.navigationController?.pushViewController(TabVC, animated: true)
            }
                
            else{
                // TODO: 로그인 실패 처리
                self.view.makeToast("ID 또는 password가 잘못됐습니다.")
                self.alertController.dismiss(animated: true)
            }
            
        }
    }
    
    @IBAction func btnFindPassword(_ sender: UIButton) {
        
        myFlag = false
        
        let findPasswordAlert = UIAlertController(title: "비밀번호 찾기", message: "해당 메일로 비밀번호 변경 메일이 전송됩니다.", preferredStyle: UIAlertController.Style.alert)
        findPasswordAlert.addTextField { (myTextField) in
            myTextField.placeholder = "이메일을 입력하세요."
        }
        let yesAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        // code..
                                        
                                        var orderedQuery:DatabaseQuery?
                                        orderedQuery = self.ref.child("users").queryOrdered(byChild: "email")
                                        orderedQuery?.observeSingleEvent(of: .value) { (snapshot) in
                                            
                                            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
                                            
                                            if snapshot.exists() {
                                                print("exists")
                                                for child in snapshotData { // in snapshot.children
                                                    let data = child as! DataSnapshot
                                                    print(data.key)
                                                    print(data.value)
                                                    
                                                    let dataDic = data.value as? NSDictionary
                                                    let email = dataDic!["email"] as? String ?? ""
                                                    
                                                    if email == findPasswordAlert.textFields![0].text {
                                                        Auth.auth().sendPasswordReset(withEmail: findPasswordAlert.textFields![0].text!) { error in
                                                            // ...
                                                        }
                                                        self.view.makeToast("해당 계정으로 비밀번호 찾기 인증메일이 발송되었습니다.")
                                                        self.myFlag = true
                                                        return
                                                    }
                                                }
                                                if self.myFlag == false {
                                                    self.view.makeToast("가입되지 않은 이메일입니다.")
                                                }
                                                
                                            }
                                            else {
                                                print("doesn't exist")
                                            }
                                            
                                        }
                    
                                            
        })
        let cancelAction = UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil)
        
        findPasswordAlert.addAction(yesAction)
        findPasswordAlert.addAction(cancelAction)
        
        present(findPasswordAlert, animated: true, completion: nil)
    }
    
   
}
