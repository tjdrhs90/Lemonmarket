import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import MobileCoreServices
import DropDown


class WriteViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UITabBarControllerDelegate  {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    var captureImage: UIImage!
    
    var postArray: Array<PostData> = []
    
    var ref: DatabaseReference = Database.database().reference()
    
    let storageRef = Storage.storage().reference()
    
    var dropDown:DropDown?
    
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var writePostTitleTxtField: UITextField!
    @IBOutlet var writePostContentTxtField: UITextView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageView2: UIImageView!
    @IBOutlet var imageView3: UIImageView!
    @IBOutlet var priceTxtField: UITextField!
    @IBOutlet var simpleAddressLabel: UILabel!
    
    @IBOutlet var categoryButton: UIBarButtonItem!
    
    
    var imageCount: Int = 0
    
    let user = Auth.auth().currentUser
    var username: String = ""
    var fullAddress: String = ""
    var simpleAddress: String = ""
    
    let date = NSDate()
    let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        dropDown = DropDown()
        // The view to which the drop down will appear on
        dropDown?.anchorView = categoryButton // UIView or UIBarButtonItem
//        dropDown?.bottomOffset = CGPoint(x: 0, y:(dropDown?.anchorView?.plainView.bounds.height)!)
        
        // The list of items to display. Can be changed dynamically
        dropDown?.dataSource = ["디지털/가전","가구/인테리어","유아동/유아도서","생활/가공식품","여성의류","여성잡화","뷰티/미용","남성패션/잡화","스포츠/레저","게임/취미","도서/티켓/음반","반려동물용품","기타 중고물품","삽니다"]
        
        // Action triggered on selection
        dropDown?.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.categoryButton.title = item
        }
        
        // Will set a custom width instead of the anchor view width
        dropDown?.width = 200
        dropDown?.textColor = UIColor.black
        dropDown?.backgroundColor = UIColor.white
        dropDown?.textFont = UIFont.systemFont(ofSize: 15)
        
        writePostContentTxtField.text = "내용을 입력하세요."
        writePostContentTxtField.textColor = UIColor.lightGray

        appDelegate.writeViewController = self //모든 뷰에서 접근 가능 (전역변수라서)
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm EEE"
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
    }
    
    @IBAction func btnCategory(_ sender: UIBarButtonItem) {
        dropDown?.show()
    }
    override func viewWillAppear(_ animated: Bool) {
        ref.child("users").child((user?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.username = value?["username"] as? String ?? ""
            self.fullAddress = value?["fullAddress"] as? String ?? ""
            self.simpleAddress = value?["simpleAddress"] as? String ?? ""
            self.usernameLabel.text = self.username
            self.simpleAddressLabel.text = self.simpleAddress
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        endEditing()
        getMapValue()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        if tabBarIndex == 1 {
            self.categoryButton.title = "카테고리"
        }
    }

    @objc func btnCategory() {
        dropDown?.show()
    }
    
    @objc func endEditing(){
        writePostTitleTxtField.resignFirstResponder()
        writePostContentTxtField.resignFirstResponder()
        priceTxtField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == writePostTitleTxtField {
            priceTxtField.becomeFirstResponder()
        } else if textField == priceTxtField {
            writePostContentTxtField.becomeFirstResponder()
        }
        return true
    }
    
    @IBAction func btnWritePost(_ sender: UIBarButtonItem) {
        
        endEditing()
        
        if imageView.image == nil {
            self.view.makeToast("이미지를 1개 이상 등록하세요.")
            return
        }
        if priceTxtField.text!.trimmingCharacters(in: .whitespaces).isEmpty || priceTxtField.text == "" {
            self.view.makeToast("가격을 입력하세요.")
            return
        }
        if writePostTitleTxtField.text!.trimmingCharacters(in: .whitespaces).isEmpty || writePostTitleTxtField.text == "" {
            self.view.makeToast("제목을 입력하세요.")
            return
        }
        if writePostContentTxtField.text!.trimmingCharacters(in: .whitespaces).isEmpty || writePostContentTxtField.text == "" ||
            writePostContentTxtField.text == "내용을 입력하세요." {
            self.view.makeToast("내용을 입력하세요.")
            return
        }
        if categoryButton.title == "카테고리" {
            self.view.makeToast("카테고리를 선택하세요.")
            return
        }
        
        setValueIntoList()
    }
    

    
    func setValueIntoList(){
        
        var curRef = self.ref.child("posts").childByAutoId()
        
        var post = PostData()
        
        //글
        let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
        
        post.username = self.username
        post.title = self.writePostTitleTxtField.text!
        post.price = Int(self.priceTxtField.text!)!
        post.content = self.writePostContentTxtField.text!
        post.time = self.formatter.string(from: self.date as Date)
        post.timestamp = "\(timeStamp)"
        post.key = curRef.key!
        post.date = timeStamp
        post.uid = self.user!.uid
        post.category = self.categoryButton.title!
        post.fullAddress = self.fullAddress
        post.simpleAddress = self.simpleAddress
        
        let postDic = post.getDict()
        
        curRef.setValue(postDic)
        
        //이미지
        switch imageCount {
        case 3:
            let data = imageView.image!.jpegData(compressionQuality: 0.5)!
            let data2 = imageView2.image!.jpegData(compressionQuality: 0.5)!
            let data3 = imageView3.image!.jpegData(compressionQuality: 0.5)!
            let riversRef = storageRef.child("posts").child(curRef.key!).child("1.jpg")
            let riversRef2 = storageRef.child("posts").child(curRef.key!).child("2.jpg")
            let riversRef3 = storageRef.child("posts").child(curRef.key!).child("3.jpg")
            let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
                riversRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    curRef.updateChildValues(["imageRef" : downloadURL.absoluteString])
                    self.imageView.image = nil
                    self.imageView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
                }
            }
            let uploadTask2 = riversRef2.putData(data2, metadata: nil) { (metadata, error) in
                riversRef2.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    curRef.updateChildValues(["imageRef2" : downloadURL.absoluteString])
                    self.imageView2.image = nil
                    self.imageView2.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
                }
            }
            let uploadTask3 = riversRef3.putData(data3, metadata: nil) { (metadata, error) in
                riversRef3.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    curRef.updateChildValues(["imageRef3" : downloadURL.absoluteString])
                    self.imageView3.image = nil
                    self.imageView3.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
                    
                }
            }
        case 2:
            let data = imageView.image!.jpegData(compressionQuality: 0.5)!
            let data2 = imageView2.image!.jpegData(compressionQuality: 0.5)!
            let riversRef = storageRef.child("posts").child(curRef.key!).child("1.jpg")
            let riversRef2 = storageRef.child("posts").child(curRef.key!).child("2.jpg")
            let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
                riversRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    curRef.updateChildValues(["imageRef" : downloadURL.absoluteString])
                    self.imageView.image = nil
                    self.imageView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
                }
            }
            let uploadTask2 = riversRef2.putData(data2, metadata: nil) { (metadata, error) in
                riversRef2.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    curRef.updateChildValues(["imageRef2" : downloadURL.absoluteString])
                    self.imageView2.image = nil
                    self.imageView2.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
                }
            }
            
        case 1:
            // Data in memory
            let data = imageView.image!.jpegData(compressionQuality: 0.5)!
            let riversRef = storageRef.child("posts").child(curRef.key!).child("1.jpg")
            let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type.
                let size = metadata.size
                // You can also access to download URL after upload.
                riversRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    curRef.updateChildValues(["imageRef" : downloadURL.absoluteString])
                    self.imageView.image = nil
                    self.imageView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
                }
            }
        default:
            break
        }
        
        self.tabBarController?.selectedIndex = 0    //탭을 전환하여 본래 타임라인으로 돌아간다.
        appDelegate.listViewController?.createAlertStart()
    }
    
    @IBAction func btnAddImage(_ sender: UIButton) {
        
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
//            imagePicker.allowsEditing = true //이미지 편집 기능
            
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            myAlert("Photo album inaccessable", message: "Application cannot access the photo album.")
        }
    }
    @IBAction func btnClearImage(_ sender: UIButton) {
        clearImg()
    }
    func clearImg() {
        imageCount = 0
        imageView.image = nil
        imageView2.image = nil
        imageView3.image = nil
        imageView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
        imageView2.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
        imageView3.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    }
    func txtClear() {
        writePostContentTxtField.text = ""
        writePostTitleTxtField.text = ""
        priceTxtField.text = ""
        imageCount = 0
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            captureImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage

        if imageCount < 3 {
            imageCount += 1
        }

        switch imageCount {
        case 1:
            imageView.image = captureImage
            imageView.backgroundColor = UIColor.white
        case 2:
            imageView2.image = captureImage
            imageView2.backgroundColor = UIColor.white
        default:
            imageView3.image = captureImage
            imageView3.backgroundColor = UIColor.white
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func myAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "내용을 입력하세요."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func getMapValue(){
        
        ref.child("users").child(user!.uid).observeSingleEvent(of: .value) { (snapshot) in
            
            var snapshotData = snapshot.children.allObjects //"DataSnapshot"타입에서 [Any] 데이터를 얻어옴
            if snapshot.exists() {
                print("exists")
                for child in snapshot.children {
                    let data = child as! DataSnapshot
                    
                    if data.key == "fullAddress" {
                        if data.value as! String == "" {
                            let alert = UIAlertController(title: "동네인증을 하지 않으면 글을 작성할 수 없습니다.", message: "동네인증 화면으로 이동합니다.", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel, handler: {ACTION in
                                let storyboard: UIStoryboard = self.storyboard!
                                let mapVC: MapViewController = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
                                self.navigationController?.pushViewController(mapVC, animated: true)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            else {
                print("doesn't exist")
            }
        }
    }
}


