import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //lazy(게으른) : 변수할당을 선언 시에 하지 않고, 변수를 호출할 때 할당함.
    lazy var listViewController: ListViewController? = nil
    lazy var writeViewController: WriteViewController? = nil
    lazy var detailViewController: DetailViewController? = nil
    lazy var myPostsViewController: MyPostsViewController? = nil
    lazy var favoriteViewController: FavoriteViewController? = nil
    lazy var mySideMenu: MySideMenuNavigationController? = nil
    lazy var myInfomationViewController: MyInfomationViewController? = nil
    lazy var modifiedViewController: ModifiedViewController? = nil
    lazy var chatViewController: ChatViewController? = nil
    lazy var chatListViewController: ChatListViewController? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        //Navigation Bar
//        UINavigationBar.appearance().barTintColor = UIColor(red: 0, green: 0/255, blue: 205/255, alpha: 1)
        UINavigationBar.appearance().barTintColor = UIColor.white
//        UINavigationBar.appearance().tintColor = UIColor.black
        UINavigationBar.appearance().tintColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        
        
        //Tab Bar
//        UITabBar.appearance().barTintColor = UIColor(red: 0, green: 0/255, blue: 205/255, alpha: 1)
        UITabBar.appearance().barTintColor = UIColor.white
//        UITabBar.appearance().tintColor = UIColor.black
        UITabBar.appearance().tintColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

struct PostData {
    var username: String = ""
    var title: String = ""
    var content: String = ""
    var time: String = ""
    var timestamp: String = ""
    var key: String = ""
    var imageRef: String = ""
    var imageRef2: String = ""
    var imageRef3: String = ""
    var price: Int = 0
    var date: Int = 0
    var uid: String = ""
    var category: String = ""
    var fullAddress: String = ""
    var simpleAddress: String = ""
    
    func getDict() -> [String:Any] {
        let dict = ["username": self.username,
                    "title": self.title,
                    "content": self.content,
                    "time": self.time,
                    "timestamp": self.timestamp,
                    "key": self.key,
                    "imageRef": self.imageRef,
                    "imageRef2": self.imageRef2,
                    "imageRef3": self.imageRef3,
                    "date": self.date,
                    "price": self.price,
                    "uid": self.uid,
                    "category": self.category,
                    "fullAddress": self.fullAddress,
                    "simpleAddress": self.simpleAddress,
        ] as [String:Any]
        return dict
    }
}

struct ChatListData {
    var username: String = ""
    var uid: String = ""
    
    func getDict() -> [String:String] {
        let dict = ["username": self.username,
                    "uid": self.uid,
        ]
        
        return dict
    }
}


struct ChatData {
    var contents: String = ""
    var time: String = ""
    var timeStamp: Int = 0
    var writerUid: String = ""
    var writerName: String = ""
    
    func getDict() -> [String:Any] {
        let dict = ["contents": self.contents,
                    "time": self.time,
                    "timeStamp": self.timeStamp,
                    "writerUid": self.writerUid,
                    "writerName": self.writerName,
            ] as [String:Any]
        
        return dict
    }
}
