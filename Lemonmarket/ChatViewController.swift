import UIKit
import FirebaseAuth
import FirebaseDatabase

class ChatViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var chatArray: Array<ChatData> = []
    var ref: DatabaseReference = Database.database().reference()
    let user = Auth.auth().currentUser
    let date = NSDate()
    let formatter = DateFormatter()
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var txtField: UITextField!
    @IBOutlet var exitButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var receiveYourname: String = ""
    var receiveMyname: String = ""
    var receiveYourUid: String = ""
    var receiveMyUid: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.chatViewController = self
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm EEE"
        getValue()
        self.navigationItem.title = receiveYourname
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        
        collectionView.reloadData()
    }
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    @objc func keyboardWillShow(_ sender:Notification){
        self.view.frame.origin.y = -220
    }
    @objc func keyboardWillHide(_ sender:Notification){
        self.view.frame.origin.y = 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatCell", for: indexPath) as! ChatCell
        let chat = self.chatArray[(chatArray.count-1)-indexPath.row] as! ChatData
        cell.txtView.text = chat.contents
        cell.timeLabel.text = chat.time
        
        if chat.writerUid == user!.uid {
            cell.txtView.textAlignment = .right
            cell.timeLabel.textAlignment = .right
        }
       
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let chat = self.chatArray[(chatArray.count-1)-indexPath.row]
        let element = chat.contents
        let fontSize: CGFloat = 17
        let limit: CGFloat = 15
        let size = CGSize(width: collectionView.frame.width, height: 1000)
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
        let estimatedFrame = element.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        let space = estimatedFrame.height - limit
        return CGSize(width: collectionView.frame.width-10, height: 125 + space )
        
//        [출처] ios swift cell의 크기에 맞게 자동으로 늘어나는 UICollectionView 만들기|작성자 Kimseong
//        http://blog.naver.com/greatsk553/221203116193

//        return CGSize(width: self.collectionView.frame.width, height: 100)
    }
    
    func receiveItem(yourname: String, myname: String, youruid: String, myuid: String)
    {
        receiveYourname = yourname
        receiveMyname = myname
        receiveYourUid = youruid
        receiveMyUid = myuid
    }
    
    @IBAction func btnSend(_ sender: UIButton) {
        if txtField.text! == "" || txtField.text!.trimmingCharacters(in: .whitespaces).isEmpty{
            self.view.makeToast("내용을 입력하세요.")
            return
        }
        setValue()
        getValue()
    }
    
    func setValue(){
        
        var curRef = self.ref.child("chats").child(user!.uid).child(receiveYourUid).childByAutoId()
        
        let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
        var chat = ChatData()
        chat.contents = txtField.text!
        chat.time = formatter.string(from: date as Date)
        chat.timeStamp = timeStamp
        chat.writerUid = user!.uid
        chat.writerName = receiveMyname
        let chatDic = chat.getDict()
        
        curRef.setValue(chatDic)
        ref.child("chats").child(receiveYourUid).child(user!.uid).child(curRef.key!).setValue(chatDic)
        
    }
    
    func getValue(){
        self.chatArray.removeAll()
        
        var ref: DatabaseReference!
        ref = Database.database().reference()
        
        var orderedQuery:DatabaseQuery?
        orderedQuery = ref?.child("chats").child(user!.uid).child(receiveYourUid).queryOrdered(byChild: "timeStamp")   
        orderedQuery?.observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            snapshotData = snapshotData.reversed()  //오름차순을 내림차순으로 바꿈
            if snapshot.exists() {
                print("exists")
                for child in snapshot.children {
                    let data = child as! DataSnapshot
//                    print(data.key)
//                    print(data.value)
                    
                    let dataDic = data.value as? NSDictionary
                    let contents = dataDic!["contents"] as? String ?? ""
                    let time = dataDic!["time"] as? String ?? ""
                    let timeStamp = dataDic!["timeStamp"] as? Int ?? 0
                    let writerUid = dataDic!["writerUid"] as? String ?? ""
                    let writerName = dataDic!["writerName"] as? String ?? ""
                    
                    
                    var chat = ChatData()
                    chat.contents = contents
                    chat.time = time
                    chat.timeStamp = timeStamp
                    chat.writerUid = writerUid
                    chat.writerName = writerName
                    
                    self.chatArray.append( chat )
                    self.collectionView.reloadData()
                }
            }
            else {
                print("doesn't exist")
            }
            
        }
        
    }
    
    @objc func endEditing(){
        txtField.resignFirstResponder()
    }
    
    @IBAction func btnExit(_ sender: UIBarButtonItem) {
        let exitAlert = UIAlertController(title: "나가기", message: "\(self.receiveYourname)님과의 채팅방을 나가시겠습니까?", preferredStyle: UIAlertController.Style.alert)
        
        let yesAction = UIAlertAction(title: "나가기", style: UIAlertAction.Style.default,
                                      handler: {ACTION in
                                        
                                        self.exitChat()
                                        
        })
        let cancelAction = UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil)
        
        exitAlert.addAction(yesAction)
        exitAlert.addAction(cancelAction)
        
        present(exitAlert, animated: true, completion: nil)
        
    }
    func exitChat() {
        self.ref.child("chats").child(user!.uid).child(receiveYourUid).removeValue()
        
        self.navigationController?.popViewController(animated: false)
        appDelegate.detailViewController?.view.makeToast("\(receiveYourname)과의 대화방을 나갔습니다.")
        appDelegate.chatListViewController?.view.makeToast("\(receiveYourname)과의 대화방을 나갔습니다.")
    }
    
}



