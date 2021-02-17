import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import DropDown

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate {
    
    let createAlertController = UIAlertController(title: nil, message: "등록중입니다.\n\n\n", preferredStyle: .alert)
    let modifiedAlertController = UIAlertController(title: nil, message: "수정중입니다.\n\n\n", preferredStyle: .alert)
    let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
    let spinnerIndicator2 = UIActivityIndicatorView(style: .whiteLarge)
    
    var prefixNum: Int = 5
    
    var refreshControl = UIRefreshControl()
    
    var newPosts = [PostData]()           // 테이블 뷰에 표시될 포스트들을 담는 배열 (5개씩)
    var postArray: Array<PostData> = []   // Firebase에서 로드된 포스트들 (전체)
    
    let storageRef = Storage.storage().reference()
    var ref: DatabaseReference = Database.database().reference()
    
    @IBOutlet var tableList: UITableView!
    @IBOutlet var categoryButton: UIBarButtonItem!
    
    let user = Auth.auth().currentUser
    
    let date = NSDate()
    let formatter = DateFormatter()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var dropDown:DropDown?
    
    var searchText: String = ""
    
    var cancelButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        self.navigationItem.title = ""
        
        dropDown = DropDown()
        // The view to which the drop down will appear on
        dropDown?.anchorView = categoryButton // UIView or UIBarButtonItem
//        dropDown?.bottomOffset = CGPoint(x: 0, y:(dropDown?.anchorView?.plainView.bounds.height)!) // 일반 버튼일 경우에 적용가능(UIBarButtonItem은 안됨)
        
        // The list of items to display. Can be changed dynamically
        dropDown?.dataSource = ["전체보기", "디지털/가전","가구/인테리어","유아동/유아도서","생활/가공식품","여성의류","여성잡화","뷰티/미용","남성패션/잡화","스포츠/레저","게임/취미","도서/티켓/음반","반려동물용품","기타 중고물품","삽니다"]
        
        // Action triggered on selection
        dropDown?.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.categoryButton.title = item
            self.getValueFromList()
        }
        
        // Will set a custom width instead of the anchor view width
        dropDown?.width = 200
        dropDown?.textColor = UIColor.black
        dropDown?.backgroundColor = UIColor.white
        dropDown?.textFont = UIFont.systemFont(ofSize: 15)
        
        appDelegate.listViewController = self //모든 뷰에서 접근 가능 (전역변수라서)
        
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.lightGray
        spinnerIndicator.startAnimating()
        spinnerIndicator2.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator2.color = UIColor.lightGray
        spinnerIndicator2.startAnimating()
        
        createAlertController.view.addSubview(spinnerIndicator)
        modifiedAlertController.view.addSubview(spinnerIndicator2)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
//        self.navigationController?.navigationBar.isTranslucent = false //반투명 해제
//        self.navigationController?.navigationBar.backgroundColor = .yellow // 그라데이션 들어감
//        self.navigationController?.navigationBar.barTintColor = UIColor(red: 222/255, green: 255/255, blue: 222/255, alpha: 1)
//        let backButton = UIBarButtonItem(title: nil, style: .plain, target: self.navigationController, action: nil)
        cancelButton = UIBarButtonItem(image:UIImage(named: "xMark"), style: .plain, target: self, action: #selector(searchReset))
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
       
        formatter.dateFormat = "yyyy-MM-dd HH:mm EEE"
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "새로고침")
        self.refreshControl.addTarget(self, action: #selector(ListViewController.refresh), for: UIControl.Event.valueChanged)
        self.tableList.addSubview(self.refreshControl) // not required when using UITableViewController

    }
    @IBAction func btnCategory(_ sender: UIBarButtonItem) {
        dropDown?.show()
    }
    @objc func searchReset() {
        self.searchText = ""
        self.navigationItem.title = ""
        getValueFromList()
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
    }
    
    //탭바 선택시 최상위로
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        if tabBarIndex == 0 {
            self.navigationController?.popToRootViewController(animated: false)
            self.categoryButton.title = "카테고리"
            self.searchText = ""
            self.navigationItem.title = ""
        }
    }
    
    @objc func refresh(){
        getValueFromList()
        self.tableList.reloadData()
        refreshControl.endRefreshing()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        //테이블 목록 갱신
        getValueFromList()
    }
    
    
    //셀 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.newPosts.count
    }
    
    // 목록 추가하기
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as! MyTableViewCell
        
        //내림차순
//        let post = self.postArray[(postArray.count-1)-indexPath.row] as! PostData
        
        let post = self.newPosts[indexPath.row]
        cell.imgView.sd_setImage(with: URL(string: post.imageRef))
        cell.titleLabel.text = post.title
        cell.timeLabel.text = post.time
        cell.simpleAddressLabel.text = post.simpleAddress
        cell.priceLabel.text = "\(post.price)" + "원"
        
        return cell
    }
    //셀 선택
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = self.newPosts[indexPath.row]
        
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
        self.newPosts.removeAll()
        
        var post = PostData()
    
        var orderedQuery:DatabaseQuery?
        orderedQuery = ref.child("posts").queryOrdered(byChild: "date")   //"date"기준으로 정렬된 posts를 얻는 질의를 작성
        
        orderedQuery?.observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            snapshotData = snapshotData.reversed()  //오름차순을 내림차순으로 바꿈
            
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

                    let tempSearchText = self.searchText.lowercased()
                    let tempTitle = title.lowercased()
                    let tempContent = content.lowercased()
                    
                    if self.categoryButton.title == "카테고리" || self.categoryButton.title == "전체보기"{
                        if tempSearchText == nil || tempSearchText == "" || tempSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
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
                        } else if tempTitle.contains(tempSearchText) || tempContent.contains(tempSearchText) {
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
                        
                    } else if category == self.categoryButton.title {
                        if tempSearchText == nil || tempSearchText == "" || tempSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
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
                        } else if tempTitle.contains(tempSearchText) || tempContent.contains(tempSearchText) {
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
            }
            else {
                print("doesn't exist")
            }
            
            self.newPosts += self.postArray.prefix(self.prefixNum)  //loadedPosts에서 일부만 posts에 저장
            self.tableList.reloadData()
        }
        
    }
    
    @IBAction func btnSearch(_ sender: UIBarButtonItem) {
        let searchAlert = UIAlertController(title: "검색", message: "검색어를 입력하세요.", preferredStyle: UIAlertController.Style.alert)
        searchAlert.addTextField { (myTextField) in
            myTextField.placeholder = "제목이나 내용을 입력하세요."
        }
        let yesAction = UIAlertAction(title: "검색", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        
                                        self.searchText = searchAlert.textFields![0].text!
                                        self.getValueFromList()
                                        if searchAlert.textFields![0].text! == nil || searchAlert.textFields![0].text! == "" ||
                                            searchAlert.textFields![0].text!.trimmingCharacters(in: .whitespaces).isEmpty{
                                            self.navigationItem.title = ""
                                        } else {
                                            self.navigationItem.title = searchAlert.textFields![0].text! + " 검색결과"
                                            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = self.cancelButton
                                        }
        })
        let cancelAction = UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil)
        
        searchAlert.addAction(yesAction)
        searchAlert.addAction(cancelAction)
        
        present(searchAlert, animated: true, completion: nil)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 마지막 셀일때 다시 통신 해서 값 받아와야한다.
        
        let height = scrollView.frame.size.height
        
        let contentYoffset = scrollView.contentOffset.y
        
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        if distanceFromBottom < height {
            
            //업데이트하고싶은 action 구현
            let pastPosts = postArray.filter{$0.date < (self.newPosts.last?.date)!}
            let pastChunkPosts = pastPosts.prefix(prefixNum)
            
            if pastChunkPosts.count > 0 {
                self.newPosts += pastChunkPosts
                self.tableList.reloadData()
            }
        }
    }
    func createAlertStart() {
        self.present(createAlertController, animated: true, completion: nil)
        let timer:Timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) -> Void in
            self.createAlertController.dismiss(animated: true)
            self.tabBarController?.view.makeToast("등록되었습니다.")
            self.appDelegate.writeViewController?.txtClear()
        });
    }
    func modifiedAlertStart() {
        self.present(modifiedAlertController, animated: true, completion: nil)
        let timer:Timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) -> Void in
            self.modifiedAlertController.dismiss(animated: true)
            self.tabBarController?.view.makeToast("수정되었습니다.")
        });
    }
}
