import UIKit
import SideMenu

//class MySideMenuNavigationController: UISideMenuNavigationController {
//
//    let customSideMenuManager = SideMenuManager()
//
//    //스토리보드의 뷰를 다 열었을 때, (안드로이드의 XML이 여기서 Nib)
//    override func awakeFromNib() {
//        super.awakeFromNib()
//
//        sideMenuManager = customSideMenuManager
//        sideMenuManager.menuPresentMode = .menuSlideIn //애니메이션 옵션 //enum으로 되어 있어서 . 만 찍으면 메뉴 나옴
//        sideMenuManager.menuWidth = 300 //사이드메뉴 보여지는 정도
//
//        //이걸 작성해야 사이드메뉴에서 버튼 눌렀을때 닫히고 뷰이동된다
//        // 이걸 적지 않으면 뷰이동은 되는데 사이드메뉴는 떠있음
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.mySideMenu = self //모든 뷰에서 사이드메뉴 접근 가능 (전역변수)
//    }
//
//}


class MySideMenuNavigationController: SideMenuNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presentationStyle = .menuSlideIn
        self.menuWidth = 300
        self.leftSide = false
        self.statusBarEndAlpha = 0.0
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mySideMenu = self //모든 뷰에서 사이드메뉴 접근 가능 (전역변수)
        
    }
    

}


