import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import Toast_Swift

class SidemenuViewController: UIViewController {

    var user = Auth.auth().currentUser
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.borderWidth = 1
        self.view.layer.borderColor = UIColor.gray.cgColor
        self.view.layer.cornerRadius = 1
        
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func btnUpdatePassword(_ sender: UIButton) {
        
        let updatePasswordAlert = UIAlertController(title: "비밀번호 변경", message: nil, preferredStyle: UIAlertController.Style.alert)
        updatePasswordAlert.addTextField { (myTextField) in
            //            myTextField.textColor = UIColor.cyan
            myTextField.placeholder = "변경 비밀번호를 입력하세요."
            myTextField.isSecureTextEntry = true
        }
        updatePasswordAlert.addTextField { (myTextField) in
            myTextField.placeholder = "변경 비밀번호를 입력하세요."
            myTextField.isSecureTextEntry = true
        }
        
        let yesAction = UIAlertAction(title: "변경", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        
                                        
                                        if updatePasswordAlert.textFields![0].text == updatePasswordAlert.textFields![1].text {
                                            Auth.auth().currentUser?.updatePassword(to: updatePasswordAlert.textFields![1].text!)
                                            self.ref.child("users/\(self.user!.uid)").updateChildValues(["password": updatePasswordAlert.textFields![1].text!])
                                            self.view.makeToast("비밀번호가 변경 되었습니다.")
                                        } else {
                                            self.view.makeToast("비밀번호가 일치하지 않습니다.")
                                        }
                                          
        })
        let cancelAction = UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil)
        
        updatePasswordAlert.addAction(yesAction)
        updatePasswordAlert.addAction(cancelAction)
        
        present(updatePasswordAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func btnLogout(_ sender: UIButton) {
        let logoutAlert = UIAlertController(title: "로그아웃", message: "로그아웃을 하시겠습니까?", preferredStyle: UIAlertController.Style.alert)
        let yesAction = UIAlertAction(title: "네", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        
                                        let firebaseAuth = Auth.auth()
                                        do {
                                            try firebaseAuth.signOut()
                                            print("logout")
                                        } catch let signOutError as NSError {
                                            print ("Error signing out: %@", signOutError)
                                        }
                                        
                                        let storyboard: UIStoryboard = self.storyboard!
                                        let newVC: LoginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                                        newVC.view.makeToast("로그아웃 되었습니다.")
                                        self.navigationController?.pushViewController(newVC, animated: true)
                                        
        })
        let cancelAction = UIAlertAction(title: "아니오", style: UIAlertAction.Style.default, handler: nil)
        
        logoutAlert.addAction(yesAction)
        logoutAlert.addAction(cancelAction)
        
        present(logoutAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func btnDeleteAccount(_ sender: UIButton) {
        let deleteAccountAlert = UIAlertController(title: "회원탈퇴", message: "탈퇴 하시겠습니까?", preferredStyle: UIAlertController.Style.alert)
        deleteAccountAlert.addTextField { (myTextField) in
            myTextField.placeholder = "비밀번호를 입력하세요."
            myTextField.isSecureTextEntry = true
        }
        let yesAction = UIAlertAction(title: "네", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        
                                        Auth.auth().signIn(withEmail: (self.user?.email)!, password: deleteAccountAlert.textFields![0].text!)  { (user, error) in
                                            
                                            if user != nil{
                                                // DB제거
                                                self.dbDelete()
                                                
                                                // 탈퇴
                                                self.user?.delete { error in
                                                    if error != nil {
                                                        // An error happened.
                                                    } else {
                                                        // Account deleted.
                                                        let storyboard: UIStoryboard = self.storyboard!
                                                        let loginVC: LoginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                                                        loginVC.view.makeToast("탈퇴 되었습니다.")
                                                        self.navigationController?.pushViewController(loginVC, animated: true)
                                                    }
                                                }
                                                
                                            }
                                            else{
                                                self.view.makeToast("비밀번호가 일치하지 않습니다.")
                                                return
                                            }
                                            
                                        }
                                        
        })
        let cancelAction = UIAlertAction(title: "아니오", style: UIAlertAction.Style.default, handler: nil)
        
        deleteAccountAlert.addAction(yesAction)
        deleteAccountAlert.addAction(cancelAction)
        
        present(deleteAccountAlert, animated: true, completion: nil)
        
    }
    func dbDelete() {
        self.ref.child("users").child(self.user!.uid).removeValue()
        self.ref.child("favorite").child(self.user!.uid).removeValue()
        
        self.ref.child("chats").child(self.user!.uid).observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            
            for child in snapshot.children {
                let data = child as! DataSnapshot
                
                self.ref.child("chats").child(data.key).child(self.user!.uid).removeValue()
            }
            self.ref.child("chats").child(self.user!.uid).removeValue()
        }
        
        self.ref.child("posts").observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            
            for child in snapshot.children {
                let data = child as! DataSnapshot
                
                let dataDic = data.value as? NSDictionary
                let uid = dataDic!["uid"] as? String ?? ""
                
                if uid == self.user?.uid {
                    self.ref.child("posts").child(data.key).removeValue()
                    self.storageRef.child("posts").child(data.key).child("1.jpg").delete { error in }
                    self.storageRef.child("posts").child(data.key).child("2.jpg").delete { error in }
                    self.storageRef.child("posts").child(data.key).child("3.jpg").delete { error in }
                }
            }
        }
        
    }
    
}
