import UIKit
import FirebaseAuth
import SwiftGifOrigin

class SplashViewController: UIViewController {

    @IBOutlet var imgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        imgView.loadGif(name: "main")
        
        let storyboard: UIStoryboard = self.storyboard!
        let loginVC: LoginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        let TabVC: UITabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        let _:Timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (timer) -> Void in
            
            if Auth.auth().currentUser == nil {
                self.navigationController?.pushViewController(loginVC, animated: true)
            } else {
                self.navigationController?.pushViewController(TabVC, animated: true)
            }
        })
    }
    
}
