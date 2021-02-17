import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImage

class MyPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate   {

    @IBOutlet var tableView: UITableView!
    
    var postArray: Array<PostData> = []
    
    let storageRef = Storage.storage().reference()
    var ref: DatabaseReference = Database.database().reference()
    let user = Auth.auth().currentUser
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.myPostsViewController = self

    }
    override func viewWillAppear(_ animated: Bool) {
        getValueFromList()
    }
    //탭바 선택시 최상위로
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as! MyTableViewCell
       
        let post = self.postArray[indexPath.row]
        cell.priceLabel.text = "\(post.price)" + "원"
        cell.titleLabel.text = post.title
        cell.timeLabel.text = post.time
        cell.imgView.sd_setImage(with: URL(string: post.imageRef))
        
        return cell
    }
    //셀 선택
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        let post = self.postArray[indexPath.row] as! PostData
        let post = self.postArray[indexPath.row]
        
        let storyboard: UIStoryboard = self.storyboard!
        let newVC: DetailViewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        newVC.receiveItem(title: post.title,
                          content: post.content,
                          username: post.username,
                          uid: post.uid,
                          image: post.imageRef,
                          image2: post.imageRef2,
                          image3: post.imageRef3,
                          price: post.price,
                          time: post.time,
                          key: post.key,
                          category: post.category,
                          fullAddress: post.fullAddress,
                          simpleAddress: post.simpleAddress)
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    func getValueFromList(){
        self.postArray.removeAll()
        
        var post = PostData()
        
        var orderedQuery:DatabaseQuery?
        orderedQuery = ref.child("posts").queryOrdered(byChild: "date")
        orderedQuery?.observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects
            snapshotData = snapshotData.reversed()
            
            if snapshot.exists() {
                print("exists")
                for child in snapshotData { // in snapshot.children
                    let data = child as! DataSnapshot
                    print(data.key)
                    print(data.value)
                    
                    let dataDic = data.value as? NSDictionary
                    let username = dataDic!["username"] as? String ?? ""
                    let title = dataDic!["title"] as? String ?? ""
                    let content = dataDic!["content"] as? String ?? ""
                    let time = dataDic!["time"] as? String ?? ""
                    let key = dataDic!["key"] as? String ?? ""
                    let imageRef = dataDic!["imageRef"] as? String ?? ""
                    let imageRef2 = dataDic!["imageRef2"] as? String ?? ""
                    let imageRef3 = dataDic!["imageRef3"] as? String ?? ""
                    let date = dataDic!["date"] as? Int ?? 0
                    let price = dataDic!["price"] as? Int ?? 0
                    let uid = dataDic!["uid"] as? String ?? ""
                    let category = dataDic!["category"] as? String ?? ""
                    let fullAddress = dataDic!["fullAddress"] as? String ?? ""
                    let simpleAddress = dataDic!["simpleAddress"] as? String ?? ""
                    
                    if uid == self.user?.uid {
                        post.username = username
                        post.title = title
                        post.content = content
                        post.time = time
                        post.key = key
                        post.imageRef = imageRef
                        post.imageRef2 = imageRef2
                        post.imageRef3 = imageRef3
                        post.price = price
                        post.date = date
                        post.uid = uid
                        post.category = category
                        post.fullAddress = fullAddress
                        post.simpleAddress = simpleAddress
                        
                        
                        self.postArray.append( post )
                    }
                    
                }
            }
            else {
                print("doesn't exist")
            }
            self.tableView.reloadData()
        }
        
    }


}
