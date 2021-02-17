import UIKit
import FirebaseDatabase
import FirebaseAuth
import Toast_Swift

class MyInfomationViewController: UIViewController, UITabBarControllerDelegate {
    
    @IBOutlet var myNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var signUpTimeLabel: UILabel!
    @IBOutlet var fullAddressLabel: UILabel!
    @IBOutlet var settingButton: UIBarButtonItem!
    
    var user = Auth.auth().currentUser
    var ref = Database.database().reference()
    
    let modifiedAlertController = UIAlertController(title: nil, message: "수정중입니다.\n\n\n", preferredStyle: .alert)
    let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.lightGray
        spinnerIndicator.startAnimating()
        
        modifiedAlertController.view.addSubview(spinnerIndicator)
        
        self.tabBarController?.delegate = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myInfomationViewController = self //모든 뷰에서 메인메뉴 접근 가능 (전역변수라서)
    }
    override func viewWillAppear(_ animated: Bool) {
        ref.child("users").child((user?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let username = value?["username"] as? String ?? ""
            let email = value?["email"] as? String ?? ""
            let signUpTime = value?["time"] as? String ?? ""
            self.myNameLabel.text = "\(username)님 반갑습니다."
            self.emailLabel.text = "이메일 : \(email)"
            self.signUpTimeLabel.text = "가입일 : \(signUpTime)"
            if value?["fullAddress"] as? String ?? "" == "" {
                self.fullAddressLabel.text = "동네인증이 되지 않았습니다."
            } else {
                self.fullAddressLabel.text = value?["fullAddress"] as? String ?? ""
            }
        })
    }
    
    //탭바 선택시 최상위로
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.navigationController?.popToRootViewController(animated: false)
    }
        
    func modifiedAlertStart() {
        self.present(modifiedAlertController, animated: true, completion: nil)
        let timer:Timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) -> Void in
            self.modifiedAlertController.dismiss(animated: true)
            self.tabBarController?.view.makeToast("수정되었습니다.")
        });
        
    }
    
    @IBAction func settingButtonClicked(_ sender: Any) {
        let sideMenuViewController: SidemenuViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SidemenuViewController") as! SidemenuViewController
        
        
        let menu = MySideMenuNavigationController(rootViewController: sideMenuViewController)
        present(menu, animated: true, completion: nil)
    }
}
