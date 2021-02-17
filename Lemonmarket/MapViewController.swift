import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class MapViewController: UIViewController, CLLocationManagerDelegate, UITabBarControllerDelegate  {
    
    let user = Auth.auth().currentUser
    var ref: DatabaseReference = Database.database().reference()
    
    let locationManager = CLLocationManager()
    
    @IBOutlet var myMap: MKMapView!
    @IBOutlet var fullAddressLabel: UILabel!
    @IBOutlet var checkLabel: UILabel!
    
    var fullAddress:String = ""
    var simpleAddress:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fullAddressLabel.text = ""
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()

        myMap.showsUserLocation = true
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //위치 권한 설정 확인
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.denied || status == CLAuthorizationStatus.restricted {
            let alert = UIAlertController(title: "위치정보", message: "설정에서 위치정보 사용을 위해 권한을 허용해주세요", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel, handler: {ACTION in
                self.tabBarController?.selectedIndex = 3
                self.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true, completion: nil)
            NSLog("위치권한 꺼져있음")
        }
        else if status == CLAuthorizationStatus.authorizedWhenInUse {
            NSLog("위치권한 켜져있음")
            locationManager.startUpdatingLocation()
        }
        
    }
    //탭바 선택시 최상위로
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    
    func goLocation(latitudeValue: CLLocationDegrees,
                    longitudeValue : CLLocationDegrees, delta span : Double) -> CLLocationCoordinate2D{
        let pLocation = CLLocationCoordinate2DMake(latitudeValue, longitudeValue)
        let spanValue = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        let pRegion = MKCoordinateRegion(center: pLocation, span: spanValue)
        myMap.setRegion(pRegion, animated: true)
        return pLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let pLocation = locations.last
        _ = goLocation(latitudeValue: (pLocation?.coordinate.latitude)!, longitudeValue: (pLocation?.coordinate.longitude)!, delta: 0.01)
        CLGeocoder().reverseGeocodeLocation(pLocation!, completionHandler: {
            (placemarks, error) -> Void in
            let pm = placemarks!.first
            
            if pm!.administrativeArea != nil { // 시
                self.fullAddress = pm!.administrativeArea!
                self.simpleAddress = pm!.administrativeArea!
            }
            if pm!.locality != nil { // 구
                self.fullAddress += " "
                self.fullAddress += pm!.locality!
                self.simpleAddress = pm!.locality!
            }
            if pm!.subLocality != nil { // 동 (안나오는 경우가 많음)
                self.fullAddress += " "
                self.fullAddress += pm!.subLocality!
                self.simpleAddress = pm!.subLocality!
            }
            if pm!.thoroughfare != nil { // 대로
                self.fullAddress += " "
                self.fullAddress += pm!.thoroughfare!
                self.simpleAddress = pm!.thoroughfare!
            }
            self.fullAddressLabel.text = self.fullAddress
            self.view.makeToast("동네인증이 완료 되었습니다.")
            self.checkLabel.text = "인증 완료"
            self.setValue()
        })
        locationManager.stopUpdatingLocation()
        
    }
    func setValue() {
        self.ref.child("users/\(user!.uid)").updateChildValues(["fullAddress": self.fullAddress,
                                                                "simpleAddress": self.simpleAddress])
    }
}
