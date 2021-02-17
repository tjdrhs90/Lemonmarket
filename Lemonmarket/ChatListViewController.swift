import UIKit
import FirebaseAuth
import FirebaseDatabase

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var chatListArray: Array<ChatListData> = []
    var myname: String = ""
    
    let user = Auth.auth().currentUser
    let ref = Database.database().reference()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.chatListViewController = self

        ref.child("users").child((user?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.myname = value?["username"] as? String ?? ""
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        getValue()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatListArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatListCell", for: indexPath)
        let chatList = chatListArray[indexPath.row]
        cell.textLabel!.text = chatList.username
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatList = chatListArray[indexPath.row]
        let storyboard: UIStoryboard = self.storyboard!
        let newVC: ChatViewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        newVC.receiveItem(yourname: chatList.username, myname: myname, youruid: chatList.uid, myuid: user!.uid)
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func getValue(){
        self.chatListArray.removeAll()
        
        ref.child("chats").child(user!.uid).observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            if snapshot.exists() {
                print("exists")
                for child in snapshot.children {
                    let data = child as! DataSnapshot
//                    print(data.key)
//                    print(data.value)
                    
                    self.ref.child("users").child(data.key).observeSingleEvent(of: .value, with: { (snapshot) in
                        // Get user value
                        let value = snapshot.value as? NSDictionary
                        let username = value?["username"] as? String ?? ""
                        let uid = value?["uid"] as? String ?? ""
                        
                        var chatList = ChatListData()
                        chatList.username = username
                        chatList.uid = uid
                        
                        self.chatListArray.append(chatList)
                        self.tableView.reloadData()
                    })
                }
            }
            else {
                print("doesn't exist")
            }
            
        }
        self.tableView.reloadData()
    }
    
}
