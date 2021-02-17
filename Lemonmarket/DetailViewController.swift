import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import DropDown

class DetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITabBarControllerDelegate  {
    
    var receiveTitle = ""
    var receiveContent = ""
    var receiveImage = ""
    var receiveImage2 = ""
    var receiveImage3 = ""
    var receiveUsername = ""
    var receiveUid = ""
    var receivePrice = 0
    var receiveTime = ""
    var receiveKey = ""
    var receiveCategory = ""
    var receiveFullAddress = ""
    var receiveSimpleAddress = ""
    
    var images: Array<String> = []
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentTxtField: UITextView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var favoriteButton: UIButton!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var modifiedButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var chatButton: UIButton!
    @IBOutlet var simpleAddressLabel: UILabel!
    @IBOutlet var userInfoButton: UIButton!
    
    let storageRef = Storage.storage().reference()
    var ref: DatabaseReference = Database.database().reference()
    let user = Auth.auth().currentUser
    var myname: String = ""
    var writerEmail: String = ""
    var writerSignUpTime: String = ""
    var writerPostCount: Int = 0
    
    var dropDown:DropDown?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        appDelegate.detailViewController = self
        
        usernameLabel.text = receiveUsername
        titleLabel.text = receiveTitle
        contentTxtField.text = receiveContent
        priceLabel.text = "\(receivePrice)" + "원"
        timeLabel.text = receiveTime
        categoryLabel.text = receiveCategory
        simpleAddressLabel.text = receiveSimpleAddress
        
        if receiveImage != "" {
            images.append(receiveImage)
        }
        if receiveImage2 != "" {
            images.append(receiveImage2)
        }
        if receiveImage3 != "" {
            images.append(receiveImage3)
        }
        
        ref.child("users").child((user?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.myname = value?["username"] as? String ?? ""
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.yellow
        pageControl.currentPageIndicatorTintColor = UIColor.white
        
        if receiveUid == user!.uid {
            self.navigationItem.rightBarButtonItems![0] = self.deleteButton
            self.navigationItem.rightBarButtonItems![1] = self.modifiedButton
            chatButton.isHidden = true
        } else {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
            chatButton.isHidden = false
        }
        
        
        
        dropDown = DropDown()
        dropDown?.anchorView = userInfoButton // UIView or UIBarButtonItem
        dropDown?.bottomOffset = CGPoint(x: 0, y:(dropDown?.anchorView?.plainView.bounds.height)!)
      
        // Action triggered on selection
        dropDown?.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
        }
        dropDown?.textColor = UIColor.black
        dropDown?.backgroundColor = UIColor.white
        dropDown?.textFont = UIFont.systemFont(ofSize: 15)
//        dropDown?.selectedTextColor = UIColor.red
        dropDown?.selectionBackgroundColor = UIColor.white
        dropDown?.cellHeight = 35
        dropDown?.cornerRadius = 15
        
        // Will set a custom width instead of the anchor view width
        //        dropDown?.width = 200
        
        ref.child("users").child(receiveUid).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.writerEmail = value?["email"] as? String ?? ""
            self.writerSignUpTime = value?["time"] as? String ?? ""
            
            self.ref.child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
                var snapshotData = snapshot.children.allObjects
                snapshotData = snapshotData.reversed()
                
                if snapshot.exists() {
                    print("exists")
                    self.writerPostCount = 0
                    for child in snapshotData { // in snapshot.children
                        let data = child as! DataSnapshot
                        print(data.key)
                        print(data.value)
                        
                        let dataDic = data.value as? NSDictionary
                        let uid = dataDic!["uid"] as? String ?? ""
                        
                        if uid == self.receiveUid {
                            self.writerPostCount += 1
                        }
                    }
                }
                else {
                    print("doesn't exist")
                }
                
                self.dropDown?.dataSource = ["\(self.receiveUsername)님의 정보","이메일 : \(self.writerEmail)","가입일 : \(self.writerSignUpTime)","동네 : \(self.receiveFullAddress)","작성한 게시글 : \(self.writerPostCount)"]
            })
            
        })
        
    }
    override func viewWillAppear(_ animated: Bool) {
        getValue()
    }
    //탭바 선택시 최상위로
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.navigationController?.popToRootViewController(animated: false)
    }
   
    func receiveItem(title: String, content: String, username: String, uid: String, image: String, image2: String, image3: String, price: Int, time: String, key: String, category: String, fullAddress: String, simpleAddress: String)
    {
        receiveUid = uid
        receiveUsername = username
        receiveTitle = title
        receiveContent = content
        receiveImage = image
        receiveImage2 = image2
        receiveImage3 = image3
        receivePrice = price
        receiveTime = time
        receiveKey = key
        receiveCategory = category
        receiveFullAddress = fullAddress
        receiveSimpleAddress = simpleAddress
    }
    
    @IBAction func btnChat(_ sender: UIButton) {
        
        let storyboard: UIStoryboard = self.storyboard!
        let newVC: ChatViewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        newVC.receiveItem(yourname: usernameLabel.text!, myname: myname, youruid: receiveUid, myuid: user!.uid)
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailImageCell", for: indexPath) as! DetailImageCell
        cell.imgView.sd_setImage(with: URL(string: images[indexPath.row]))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: 200)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            pageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        }
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            pageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        }
    }
    
    @IBAction func btnModifiedPost(_ sender: UIBarButtonItem) {
        
        let storyboard: UIStoryboard = self.storyboard!
        let newVC: ModifiedViewController = storyboard.instantiateViewController(withIdentifier: "ModifiedViewController") as! ModifiedViewController
        newVC.receiveItem(title: receiveTitle,
                          content: receiveContent,
                          username: receiveUsername,
                          uid: receiveUid,
                          image: receiveImage,
                          image2: receiveImage2,
                          image3: receiveImage3,
                          price: receivePrice,
                          time: receiveTime,
                          key: receiveKey,
                          category: receiveCategory)
        self.navigationController?.pushViewController(newVC, animated: true)
        
    }
    @IBAction func btnDeletePost(_ sender: UIBarButtonItem) {
        let deleteAlert = UIAlertController(title: "글 삭제", message: "해당 게시글을 삭제하시겠습니까?", preferredStyle: UIAlertController.Style.alert)
        
        let yesAction = UIAlertAction(title: "삭제", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        
                                        self.deletePost()
                                        
        })
        let cancelAction = UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil)
        
        deleteAlert.addAction(yesAction)
        deleteAlert.addAction(cancelAction)
        
        present(deleteAlert, animated: true, completion: nil)
        
    }
    func deletePost() {
        self.ref.child("posts").child(receiveKey).removeValue()
        
        var curRef = self.ref.child("favorite").queryOrdered(byChild: self.receiveKey).queryEqual(toValue: self.receiveKey)
        curRef.observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            
            if snapshot.exists() {
                print("exists")
                for child in snapshotData { // in snapshot.children
                    let data = child as! DataSnapshot
                    self.ref.child("favorite").child(data.key).child(self.receiveKey).removeValue()
                }
            }
        }
        
        // Create a reference to the file to delete
        storageRef.child("posts").child(self.receiveKey).child("1.jpg").delete { error in
            if let error = error {
                // Uh-oh, an error occurred!
            } else {
                // File deleted successfully
            }
        }
        storageRef.child("posts").child(self.receiveKey).child("2.jpg").delete { error in }
        storageRef.child("posts").child(self.receiveKey).child("3.jpg").delete { error in }
        
        self.navigationController?.popViewController(animated: false)
        appDelegate.listViewController?.view.makeToast("해당 게시글을 삭제하였습니다.")
        appDelegate.myPostsViewController?.view.makeToast("해당 게시글을 삭제하였습니다.")
        appDelegate.favoriteViewController?.view.makeToast("해당 게시글을 삭제하였습니다.")
    }
    
    @IBAction func btnFavorite(_ sender: UIButton) {
        
        //애니메이션
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear,
                       animations: {
                        sender.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        }) {
            (success) in
            sender.isSelected =  !sender.isSelected
            UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear,
                           animations: {
                            sender.transform = .identity
            },completion: nil)
        }
        
        //노멀
//        if sender.isSelected {
//            sender.isSelected = false
//        } else {
//            sender.isSelected = true
//        }
        
        if sender.isSelected {
            deleteValue()
            self.view.makeToast("관심목록에서 제거 되었습니다.")
        } else {
            setValue()
            self.view.makeToast("관심목록에 추가 하였습니다.")
        }
        
    }
    func setValue(){
        self.ref.child("favorite").child(user!.uid).child(receiveKey).setValue("\(receiveKey)")
    }
    func deleteValue(){
        self.ref.child("favorite").child(user!.uid).child(receiveKey).removeValue()
    }
    func getValue(){
        var curRef = self.ref.child("favorite").child(user!.uid)
        curRef.observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            
            if snapshot.exists() {
                print("exists")
                for child in snapshotData { // in snapshot.children
                    let data = child as! DataSnapshot

                    let key = data.value as? String ?? ""

                    if key == self.receiveKey {
                        self.favoriteButton.isSelected = true
                        print("관심 목록에 있음")
                    } else {
                        print("관심 목록에 없음")
                    }
                    
                }
            }
            else {
                print("doesn't exist")
            }
            
        }
    }
    
    @IBAction func btnUserInfo(_ sender: UIButton) {
        dropDown?.show()
    }
    
}
