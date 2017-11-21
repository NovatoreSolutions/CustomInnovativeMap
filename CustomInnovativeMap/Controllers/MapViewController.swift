//
//  MapViewController.swift
//  ANA
//
//  Created by Novatore-iOS on 10/04/2017.
//  Copyright © 2017 Novatore Solutions. All rights reserved.
//


import UIKit
import GoogleMaps
import AVFoundation
import GooglePlaces
import HMSegmentedControl
import SYBlinkAnimationKit
import Alamofire
import Toast_Swift
import Intercom
import Crashlytics

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //Bools
    static var onPackageViewController = false
    static var onScheduleViewController = false
    static var editOrderBackPressed = false
    
    var checkForMultipleOrderAlert = true
    var isFirstResponse: Bool = true
    var isFirstTextField: Bool = true
    var isSecondTextField: Bool = false
    var isSwipeUp = false
    var fromEditOrder = false
    var isGeoFenced: Bool = false
    var isLoadedFirstTime = true
    var doesServerRespondForUserSavedSearches = false
    var didComeFromSummaryScreen: Bool = false
    var location_is_offline: Bool = false
    var text_field_is_responder_location_should_work: Bool = false
    
    //Text Fields
    let fromTextField = UITextField()
    let toTextField = UITextField()
    
    //Buttons
    let fromSuperView = SYButton()
    let toSuperView = SYButton()
    var addNewToButton = UIButton()
    let fromRemoveButton = UIButton()
    let toRemoveButton = UIButton()
    var bottomButton = UIButton()
    let rightSliderButton = UIButton()
    var goToScheduleButton: UIButton?
    
    //Arrays
    var dropDownArray: [String] = []
    var longLatSearchPlacesIDs: [String] = []
    var saveSearches: [UserSaveSearches] = []
    var items: [String] = []
    var packages: [Package] = []
    var viewsInScrollView: [UIView] = []
    let sampleBGColors: Array<UIColor> = [UIColor.white, UIColor.white, UIColor.white, UIColor.white, UIColor.white]
    
    //Views
    let contentView = UIView()
    let rightTopIntercomView = UIView()
    let v = UIImageView()
    var mapView_: GMSMapView? = nil
    var segmentSuperView = UIView()
    var scrollView = UIScrollView()
    let dropDownTableView: UITableView = UITableView()
    
    //Objects
    var locationManager = CLLocationManager()
    let toMarker = GMSMarker()
    var currentLocationMarker = GMSMarker()
    var segmentControl = SegmentedControlExistingSegmentTapped()
    var currentLongitudeLatitudeOfFromFieldBeforeAddingOrder: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var currentLongitudeLatitudeOfToFieldBeforeAddingOrder: CLLocationCoordinate2D = CLLocationCoordinate2D()
    static var packageReturnedFromPackageViewController: Package?
    var timer: Timer? = nil
    
    //Hard Coded Values
    var slideDownYPosition: CGFloat = -1
    var slideUpYPosition: CGFloat = -1
    var totalPages = 5
    var indexForPackage = -1
    var orderToEdit: Int = -1
    
    //Labels
    let chatCountLbl = UILabel()
    
    
    override func viewWillDisappear(_ animated: Bool) {
      
        NotificationCenter.default.removeObserver(self)
      
    }
    
    func geoFencingServerCall(lines: [String]?){
        
        SVProgressHUD.show()
        var ad : CLLocationCoordinate2D = CLLocationCoordinate2D()
        var parameters: Parameters = ["lat":-1 , "lng": -1]
        if isFirstTextField {
            
            parameters = ["lat":self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude , "lng":
                self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude]
            
        }
        else if isSecondTextField {
            
            parameters = ["lat":self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude , "lng": self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude]
            
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Basic YW5hX2F1dGhlbnRpY2F0ZWRfdXNlcjpAbkBfdXNlcg==",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        Alamofire.request(URLs.geoFencing, method: .post , parameters: parameters as Parameters , headers: headers).responseJSON { response in
            debugPrint(response)
            if(response.result.description == "SUCCESS"){
                let responseDic = response.value as! NSDictionary
                if responseDic.value(forKey: "message") as! String == "service is currently not available in your area"{
                    
                    if self.isFirstTextField{
                        
                        self.fromTextField.becomeFirstResponder()
                        self.v.image = UIImage(named: "mapPin-1")
                        self.fromTextField.placeholder = "ANA is currently not available in your area"
                        
                    }
                    else if self.isSecondTextField{
                        
                        self.v.image = UIImage(named: "mapPin")
                        self.toTextField.placeholder = "ANA is currently not available in your area"
                        self.removebuttons()
                        
                    }
                    
                    self.isGeoFenced = false
                    SVProgressHUD.dismiss()
                    
                }
                else if responseDic.value(forKey: "message") as! String == "Service is available in this area"{
                    
                    if self.isFirstTextField{
                        self.removebuttons()
                    }
                    else{
                        self.removebuttons()
                    }
                    self.isGeoFenced = true
                    ad.latitude = self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude
                    ad.longitude = self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude
                    self.getAddress(coordinate: ad)
                    SVProgressHUD.dismiss()
                    
                }
                
            }
            else{
                SVProgressHUD.dismiss()
                let alert = Global.alertAction(title: "Action failed", message: (response.result.error?.localizedDescription)!)
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    }
    
    func updateUnreadCount(){
        if(Intercom.unreadConversationCount() == 0){
            
            self.chatCountLbl.isHidden = true
            self.chatCountLbl.layer.cornerRadius = 7.5
            self.chatCountLbl.layer.masksToBounds = true
            
        }
        else{
            
            self.chatCountLbl.isHidden = false
            self.chatCountLbl.layer.cornerRadius = 7.5
            self.chatCountLbl.layer.masksToBounds = true
            self.chatCountLbl.text =  "\(Intercom.unreadConversationCount())"
            
        }
    }
    
    
    
    // UITextField Methods
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        self.dropDownTableView.isHidden = true
        return true
    }
    
    public override func textFieldDidBeginEditing(_ textField: UITextField){
        
        mapView_?.addSubview(self.dropDownTableView)
        showShadowAroundDropDownTableView()
        self.dropDownTableView.separatorColor = UIColor.clear
        self.dropDownTableView.delegate = self
        self.dropDownTableView.dataSource = self
        self.dropDownTableView.isHidden = true
        self.dropDownTableView.backgroundColor = UIColor(netHex: 0xffffff)
        self.dropDownTableView.keepLeftInset.Equal = 30
        self.dropDownTableView.keepRightInset.Equal = 30
        self.dropDownTableView.keepTopOffsetTo(self.toTextField)?.Equal = 2
        self.dropDownTableView.keepHeight.Equal = 150
        self.dropDownTableView.isScrollEnabled = false
        
        if textField.tag == 1 {
            
            if checkForMultipleOrderAlert==true{
                if textField.tag == 1 {
                    
                    fromRemoveButton.isHidden=false
                    toRemoveButton.isHidden=true
                    if(packages.count > 1){
                        
                        let alertController = UIAlertController(title: "Warning", message: "Changing from location will change it for all orders", preferredStyle:UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel)
                        { action -> Void in
                            self.fromTextField.text = ""
                            self.fromTextField.placeholder="Pickup Location"
                            self.fromRemoveButton.isHidden=true
                            self.checkForMultipleOrderAlert=false
                            self.fromTextField.becomeFirstResponder()
                            
                        })
                        alertController.addAction(UIAlertAction(title: "Cancel" , style: UIAlertActionStyle.destructive)
                        { action -> Void in
                            
                        })
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
            
            self.isFirstTextField = true
            self.isSecondTextField = false
            fromSuperView.startAnimating()
            text_field_is_responder_location_should_work=true
            toSuperView.stopAnimating()
            if (self.fromTextField.text?.characters.count)! <= 0 {
                
                isFirstResponse = true
                self.dropDownTableView.isHidden = true
                
            }
            else {
                
                isFirstResponse = false
                fromRemoveButton.isHidden=false
                text_field_is_responder_location_should_work=false
                self.dropDownTableView.isHidden = true
                
            }
        }
        else if textField.tag == 2 {
            
            self.isSecondTextField = true
            self.isFirstTextField = false
            text_field_is_responder_location_should_work=true
            
            toTextField.becomeFirstResponder()
            fromSuperView.stopAnimating()
            toSuperView.startAnimating()
            
            if (self.toTextField.text?.characters.count)! <= 0 {
                
                fromSuperView.stopAnimating()
                isFirstResponse = true
                self.dropDownTableView.isHidden = true
                
            }
            else {
                
                isFirstResponse = false
                toRemoveButton.isHidden=false
                text_field_is_responder_location_should_work=false
                self.dropDownTableView.isHidden = true
                
            }
        }
        self.dropDownArray = []
        self.dropDownTableView.reloadData()
        
    }
    
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool{
        
        visibleOrInvisibleDocumentButton()
        removebuttons()
        self.dropDownArray = []
        self.dropDownTableView.reloadData()
        self.dropDownTableView.isHidden = true
        text_field_is_responder_location_should_work=false
        
        return true
    }
    
    
    public func textFieldDidEndEditing(_ textField: UITextField){
        
        text_field_is_responder_location_should_work=false
        
    }
    
    
    @available(iOS 10.0, *)
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason){
        text_field_is_responder_location_should_work=false
        
        if toTextField.text?.isEmpty==false{
            
            toRemoveButton.isHidden=true
            
        }
        else{
            
            toRemoveButton.isHidden=false
            
        }
        
        if fromTextField.text?.isEmpty==false{
            
            fromRemoveButton.isHidden=true
            
        }
        else{
            
            fromRemoveButton.isHidden=false
            
        }
    }
    
    
    func getHints(timer: Timer) {
        var userInfo = timer.userInfo as! [String: UITextField]
        let textField: UITextField = userInfo["textField"]!
        visibleOrInvisibleDocumentButton()
        
        if (textField.text?.characters.count)! <= 0 {
            
            self.isFirstResponse = true
            self.dropDownTableView.isHidden = true
            
            self.dropDownArray = []
            self.dropDownTableView.reloadData()
            
        }
        else {
            
            self.isFirstResponse = false
            self.dropDownTableView.isHidden = true
            let placesClient = GMSPlacesClient()
            let visibleRegion = mapView_?.projection.visibleRegion()
            let bounds = GMSCoordinateBounds(coordinate: (visibleRegion?.farLeft)!, coordinate: (visibleRegion?.nearRight)!)
            let filter = GMSAutocompleteFilter()
            filter.country = "qa"
            filter.type = .establishment
            placesClient.autocompleteQuery(textField.text!, bounds: bounds, filter: filter, callback: {
                (results, error) -> Void in
                self.dropDownArray = []
                self.longLatSearchPlacesIDs = []
                guard error == nil else {
                    self.dropDownTableView.reloadData()
                    return
                }
                if let results = results {
                    var number = 0
                    for result in results {
                        
                        self.dropDownArray.append("\(result.attributedPrimaryText.string)")
                        self.longLatSearchPlacesIDs.append(result.placeID!)
                        
                    }
                    if number > 0 {
                        
                        self.dropDownTableView.isHidden = false
                        self.dropDownTableView.reloadData()
                        
                    }
                    else {
                        
                        if self.isFirstResponse == false {
                            
                            self.dropDownTableView.isHidden = true
                            
                        }
                    }
                }
            })
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        
        if( (textField.text?.characters.count)! <= 1){
            self.dropDownTableView.isHidden = true
            if textField.tag==1{
                
                fromRemoveButton.isHidden=false
                toRemoveButton.isHidden=true
                
            }else if textField.tag==2{
                
                fromRemoveButton.isHidden=true
                toRemoveButton.isHidden=false
                
            }
        }
        else{
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(
                timeInterval: 0,
                target: self,
                selector: #selector(getHints(timer:)),
                userInfo: ["textField": textField],
                repeats: false)
            
        }
        return true
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool{
        
        visibleOrInvisibleDocumentButton()
        
        if textField.tag == 0 {
            
            self.fromTextField.text = " "
            
        }
        else {
            self.toTextField.text = " "
        }
        
        return false
    }
    
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        
        removebuttons()
        hideKeyboardAndDropDownTableView(sender: textField)
        
        return true
    }
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        setPlaceHolderText()
        removebuttons()
        haveAccessToLocationServices()
        
        fromTextField.addTarget(self, action: #selector(self.fromTextFieldLocationChangeWillChangeLocationForAll), for: .allTouchEvents)
        toTextField.addTarget(self, action: #selector(self.fromTextFieldLocationChangeWillChangeLocationForAll), for: .allTouchEvents)
        fromTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        toTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        Global.turnOffOnSliderPanGesture(panGestureOff: false)
        configureLocationManager()
        dropDownTableView.register(UINib(nibName: "DropDownCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
        
    }
    
    func fromTextFieldLocationChangeWillChangeLocationForAll(){
        
        if packages.count > 1{
            
            checkForMultipleOrderAlert=true
            
        }
        
        if didComeFromSummaryScreen==true{
            
            didComeFromSummaryScreen=false
            
        }
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if( (textField.text?.characters.count)! <= 0){
            
            removebuttons()
            
        }
    }
    
    
    func setPlaceHolderText(){
        
        self.fromTextField.placeholder = "Pickup Location"
        self.toTextField.placeholder = "Where To?"
        self.fromTextField.delegate = self
        self.toTextField.delegate = self
        
    }
    
    func configureLocationManager() {
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            
        }
    }
    
    func haveAccessToLocationServices() {
        
        switch(CLLocationManager.authorizationStatus())
        {
        case .restricted:
            
            createUI()
            
        case .notDetermined:
            
            createUI()
            
        case .denied:
            
            createUI()
            
        case .authorizedAlways, .authorizedWhenInUse:
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if(packages.count < 1){
            
            rightSliderButton.isHidden = false
            rightTopIntercomView.isHidden = false
            
        }
            
        else{
            
            rightSliderButton.isHidden = true
            rightTopIntercomView.isHidden = true
            
        }
        if(UserDefaults.standard.value(forKey: "back") != nil){
            if(UserDefaults.standard.value(forKey: "back") as! String == "backfromloginpackagedetail"){
                ViewController.onPackageViewController = false
                if(packages.count > 0){
                    
                    var count = packages.count
                    if(ViewController.editOrderBackPressed){
                        ViewController.editOrderBackPressed = false
                        
                    }
                    else{
                        
                        count = packages.count - 1
                        packages.remove(at: count)
                        
                    }
                    if(count >= 1){
                        
                        createSegmentSuperView()
                        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
                        swipeUp(recognizer: bottomSwipe)
                        UserDefaults.standard.removeObject(forKey: "back")
                        
                    }
                    else{
                        
                        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
                        swipeUp(recognizer: bottomSwipe)
                        UserDefaults.standard.removeObject(forKey: "back")
                        
                    }
                }
                else{
                    
                    UserDefaults.standard.removeObject(forKey: "back")
                    
                }
            }
        }
        else{
            
            if(ViewController.onPackageViewController || ViewController.onScheduleViewController) {
                
                ViewController.onPackageViewController = false
                totalPages = packages.count
                
                if(ViewController.packageReturnedFromPackageViewController != nil){
                    
                    addNewToButton.isHidden = false
                    indexForPackage = totalPages-1
                    createSegmentSuperView()
                    
                    if goToScheduleButton == nil {
                        
                        createScheduleButton()
                        
                    }
                    else {
                        
                        goToScheduleButton?.isHidden = false
                        
                    }
                    
                    let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
                    swipeUp(recognizer: bottomSwipe)
                    
                    if(self.segmentControl.selectedSegmentIndex == 1){
                        
                        self.scrollView.setContentOffset(CGPoint(x:self.view.frame.width * 2 , y:0), animated: true)
                        
                    }
                    else if self.segmentControl.selectedSegmentIndex == 2{
                        
                        self.scrollView.setContentOffset(CGPoint(x:self.view.frame.width * 3 , y:0), animated: true)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateUnreadCount),
                                               name: NSNotification.Name.IntercomUnreadConversationCountDidChange,
                                               object: nil)
        if(packages.count < 1){
            rightSliderButton.isHidden = false
        }
    }
    
    func goToScheduleScreen() {
        
        if Global.isGuest{
            
            getSenderGuestDetailsFromUserDefaultsAndStoreInModel()
            
        }
        
        if Reachability.isConnectedToNetwork(){
            
            ViewController.onScheduleViewController = true
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainViewController = storyboard.instantiateViewController(withIdentifier: "ScheduleViewController") as! ScheduleViewController
            mainViewController.packages = self.packages
            present(mainViewController, animated: true, completion: nil)
            
        }else{
            let alertController = Global.alertAction(title: "No Internet Connection", message: "Internet connection appears to be offline")
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func getSenderDetailsFromUserDefaultsAndStoreInModel() {
        
        let defaults = UserDefaults.standard
        
        for i in 0..<packages.count {
            
            let sender = SenderDetail()
            let name = defaults.value(forKey: "name") as? String
            let email = defaults.value(forKey: "email") as? String
            let cellNo = defaults.value(forKey: "cellNumber") as? String
            let id = defaults.value(forKey: "user_id") as? Int
            sender.senderCell = cellNo!
            sender.senderEmail = email!
            sender.senderName = name!
            sender.senderId = id!
            packages[i].senderDetail = sender
            
        }
    }
    
    func getSenderGuestDetailsFromUserDefaultsAndStoreInModel() {
        let defaults = UserDefaults.standard
        for i in 0..<packages.count {
            let sender = SenderDetail()
            let name = defaults.value(forKey: "guestName") as? String
            let email = defaults.value(forKey: "guestEmail") as? String
            let cellNo = defaults.value(forKey: "guestCellNumber") as? String
            sender.senderCell = cellNo!
            sender.senderEmail = email!
            sender.senderName = name!
            packages[i].senderDetail = sender
            
        }
    }
    
    func createSegmentSuperView() {
        if(packages.count > 1){
           
            slideDownYPosition = self.view.frame.height - 90
            slideUpYPosition = self.view.frame.height - 230  //- 160
            segmentSuperView = UIView(frame: CGRect(x:0, y: 0  , width: self.view.frame.width, height: 230 /* 160*/))
            self.mapView_?.addSubview(segmentSuperView)
            segmentSuperView.backgroundColor = UIColor.white
            
            if didComeFromSummaryScreen==false{
                
                configureScrollView()
                
            }
            
            createScrollView()
            createSegmentControl()
            createBottomButton()
            refreshBottomSheet()
        }
    }
    
    func createBottomButton(){
        
        bottomButton = UIButton(frame: CGRect(x: 0, y: self.view.frame.height - 40 , width: self.view.frame.width, height: 40))
        bottomButton.backgroundColor = Color.appColor
        bottomButton.titleLabel?.font = Constants().setRegularFont(Size: 15)
        
        if(packages.count > 0){
            
            bottomButton.setTitle("SCHEDULE", for: .normal)
            
        }
        else{
            
            bottomButton.setTitle("NEXT", for: .normal)
            
        }
        bottomButton.addTarget(self, action: #selector(bottomButtonAction), for: .touchUpInside)
        self.view?.addSubview(bottomButton)
        
    }
    
    func createSegmentControl() {
        
        self.segmentControl = SegmentedControlExistingSegmentTapped(sectionTitles: items)
        self.segmentControl.selectionStyle = .textWidthStripe
        self.segmentControl.selectionIndicatorLocation = .down
        self.segmentControl.selectionIndicatorHeight = 2
        self.segmentControl.selectionIndicatorColor = UIColor(netHex:0x724d5c)
        self.segmentSuperView.addSubview(segmentControl)
        self.segmentControl.keepTopInset.Equal = 0
        self.segmentControl.keepLeftInset.Equal = 0
        self.segmentControl.keepRightInset.Equal = 0
        self.segmentControl.keepHeight.Equal = 50
        self.segmentControl.selectedSegmentIndex = items.count - 1
        segmentControl.addTarget(self, action: #selector(ViewController.segmentedValueChanged(_:)), for: .valueChanged)
        
        let topSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        topSwipe.direction = .up
        self.segmentControl.addGestureRecognizer(topSwipe)
        
        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        bottomSwipe.direction = .down
        self.segmentControl.addGestureRecognizer(bottomSwipe)
    }
    
    func segmentedValueChanged(_ sender:UISegmentedControl!) {
        
        self.indexForPackage = sender.selectedSegmentIndex
        self.fromTextField.text = self.packages[sender.selectedSegmentIndex].toFromObj?.from
        self.toTextField.text = self.packages[sender.selectedSegmentIndex].toFromObj?.to
        let fancy = GMSCameraPosition.camera(withLatitude: (self.packages[sender.selectedSegmentIndex].toFromObj?.toLat)!,
                                             longitude: (self.packages[sender.selectedSegmentIndex].toFromObj?.toLong)!, zoom: 14, bearing: 0, viewingAngle: 0)
        self.mapView_?.camera = fancy
        self.bottomButton.isEnabled = true
        var newFrame = scrollView.frame
        newFrame.origin.x = newFrame.size.width * CGFloat(sender.selectedSegmentIndex)
        DispatchQueue.main.async {
            let cg = CGPoint(x: newFrame.origin.x, y: 0)
            self.scrollView.setContentOffset(cg, animated: true)
        }
        indexForPackage = sender.selectedSegmentIndex
    }
    
    func updateDataOnDelete(){
        self.indexForPackage = self.segmentControl.selectedSegmentIndex
        self.fromTextField.text = self.packages[self.segmentControl.selectedSegmentIndex].toFromObj?.from
        self.toTextField.text = self.packages[self.segmentControl.selectedSegmentIndex].toFromObj?.to
        let fancy = GMSCameraPosition.camera(withLatitude: (self.packages[self.segmentControl.selectedSegmentIndex].toFromObj?.toLat)!,
                                             longitude: (self.packages[self.segmentControl.selectedSegmentIndex].toFromObj?.toLong)!, zoom: 14, bearing: 0, viewingAngle: 0)
        self.mapView_?.camera = fancy
        self.bottomButton.isEnabled = true
        var newFrame = scrollView.frame
        newFrame.origin.x = newFrame.size.width * CGFloat(self.segmentControl.selectedSegmentIndex)
        DispatchQueue.main.async {
            let cg = CGPoint(x: newFrame.origin.x, y: 0)
            self.scrollView.setContentOffset(cg, animated: true)
        }
    }
    
    func swipe() {
        if isSwipeUp {
            isSwipeUp = false
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {() -> Void in
                self.segmentSuperView.frame = CGRect(x: CGFloat(0), y: self.view.frame.height - 90, width: self.view.frame.width, height: 230)
                
            }, completion: {(_ finished: Bool) -> Void in
                
            })
        }
        else {
            isSwipeUp = true
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {() -> Void in
                self.segmentSuperView.frame = CGRect(x: CGFloat(0), y: self.view.frame.height-230, width: self.view.frame.width, height: 230)
                
            }, completion: {(_ finished: Bool) -> Void in
            })
        }
    }
    
    func swipeUp(recognizer: UISwipeGestureRecognizer) {
        isSwipeUp = false
        swipe()
    }
    
    func swipeDown(recognizer: UISwipeGestureRecognizer) {
        isSwipeUp = true
        swipe()
    }
    
    func createScrollView() {
        self.segmentSuperView.addSubview(self.scrollView)
        
        self.scrollView.keepLeftInset.Equal = 0
        self.scrollView.keepTopInset.Equal = 50
        self.scrollView.keepRightInset.Equal = 0
        self.scrollView.keepBottomInset.Equal = 50
        
    }
    
    func bottomButtonAction(sender: UIButton!) {
        
        if didComeFromSummaryScreen{
            
            didComeFromSummaryScreen=false
            
        }
        
        if(sender?.titleLabel?.text == "NEXT"){
            
            if(fromTextField.text == ""){
                
                let alertController = Global.alertAction(title: "Warning", message: "Please enter the Pickup location")
                self.present(alertController, animated: true, completion: nil)
                
            }
            else if (toTextField.text != ""){
                
                if(self.isGeoFenced){
                    
                    if(toTextField.text == ""){
                        
                        let alertController = Global.alertAction(title: "Warning", message: "Please enter the Where To location")
                        self.present(alertController, animated: true, completion: nil)
                        
                    }
                    else if(toTextField.text != ""){
                        
                        if(self.isGeoFenced){
                            
                            if (UserDefaults.standard.value(forKey: "user_id") != nil){
                                
                                goToPackageDetailScreenLoginFlow()
                                
                            }
                            else{
                                
                                goToPackageDetailScreen()
                                
                            }
                        }
                        else{
                            
                            let alertController = Global.alertAction(title: "Warning", message: "Please enter the valid Where To location")
                            self.present(alertController, animated: true, completion: nil)
                            
                        }
                    }
                }
                else{
                    let alertController = Global.alertAction(title: "Warning", message: "Please enter a valid Pickup location")
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            else if(toTextField.text == ""){
                let alertController = Global.alertAction(title: "Warning", message: "Please enter the Where To location")
                self.present(alertController, animated: true, completion: nil)
                
            }
        }
        else if (sender?.titleLabel?.text == "SCHEDULE"){
            
            if toTextField.text?.isEmpty==true{
                
                let alertViewController = Global.alertAction(title: "Please Enter Where to Location!", message: "")
                self.present(alertViewController, animated: true , completion: nil)
                
            }else if  fromTextField.text?.isEmpty==true{
                
                let alertViewController = Global.alertAction(title: "Please Enter From to Location!", message: "")
                self.present(alertViewController, animated: true , completion: nil)
                
            }else{
                
                goToScheduleScreen()
                
            }
        }
    }
    
    
    
    func configureScrollView() {
        
        viewsInScrollView = []
        
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.scrollsToTop = false
        
        self.scrollView.contentSize = CGSize(width: self.view.frame.width * CGFloat(totalPages), height: scrollView.frame.size.height)
        scrollView.delegate = self
        totalPages = packages.count
        
        for i in 0 ..< totalPages {
            
            items.append("Order \(i+1)")
            let testView = Bundle.main.loadNibNamed("BottomSheet", owner: self, options: nil)?[0] as! UIView
            let topSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
            topSwipe.direction = .up
            testView.addGestureRecognizer(topSwipe)
            let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
            bottomSwipe.direction = .down
            testView.addGestureRecognizer(bottomSwipe)
            testView.frame = CGRect(x: CGFloat(i) * self.view.frame.size.width, y: scrollView.frame.origin.y , width: scrollView.frame.size.width, height: scrollView.frame.size.height)
            testView.backgroundColor = sampleBGColors[i]
            let fromName = testView.viewWithTag(1) as! UILabel
            let fromAddress = testView.viewWithTag(2) as! UILabel
            fromAddress.text = "\((packages[i].toFromObj?.from!)!)"
            let toName = testView.viewWithTag(3) as! UILabel
            let fromN = getFromName()
            
            if Global.isSignedIn {
                
                if packages[i].isSelfRecipient! {
                    
                    fromName.text = "\(fromN)"
                    toName.text = "\((packages[i].recipient?.name)!)"
                    
                }
                else {
                    
                    if packages[i].isReceiver!{
                        
                        fromName.text = "\((packages[i].senderDetail?.senderName)!)"
                        toName.text = "\(fromN)"
                        addNewToButton.isHidden=true
                        
                    }
                    else if packages[i].isSender!{
                        
                        fromName.text = "\(fromN)"
                        toName.text = "\((packages[i].recipient?.name)!)"
                        
                    }
                }
            }
            else {
                if packages[i].isSelfRecipient! {
                    
                    fromName.text = "\((packages[i].recipient?.name)!)"
                    toName.text = "\((packages[i].recipient?.name)!)"
                    
                }
                else {
                    if packages[i].isReceiver!{
                        
                        fromName.text = "\((packages[i].senderDetail?.senderName)!)"
                        toName.text = "\((packages[i].recipient?.name)!)"
                        addNewToButton.isHidden=true
                        
                    }
                    else if packages[i].isSender!{
                        
                        fromName.text = "\((packages[i].senderDetail?.senderName)!)"
                        toName.text = "\((packages[i].recipient?.name)!)"
                        
                    }
                }
                
            }
            
            let toAddress = testView.viewWithTag(4) as! UILabel
            toAddress.text = "\((packages[i].toFromObj?.to!)!)"
            let totalItems = testView.viewWithTag(6) as! UILabel
            totalItems.text = "\(Int((packages[i].packageQuantity?.smallQuantity)! + (packages[i].packageQuantity?.mediumQuantity)! + (packages[i].packageQuantity?.largeQuantity!)!))"
            
            if packages[i].getProductsTotal() == 0 {
                
                var totalValue = testView.viewWithTag(8) as! UILabel
                totalValue.isHidden = true
                totalValue = testView.viewWithTag(7) as! UILabel
                totalValue.isHidden = true
                
            }
            else {
                
                let totalValue = testView.viewWithTag(8) as! UILabel
                totalValue.text = "QR \(packages[i].getProductsTotal()) "
                
            }
            let iconImage = testView.viewWithTag(9) as! UIImageView
            iconImage.backgroundColor = UIColor.clear
            let removeButton = testView.viewWithTag(10) as! UIButton
            removeButton.tag = i
            removeButton.addTarget(self, action: #selector(self.removePackage), for: .touchUpInside)
            let editButton = testView.viewWithTag(11) as! UIButton
            editButton.tag = i
            editButton.addTarget(self, action: #selector(self.editOrder), for: .touchUpInside)
            viewsInScrollView.append(testView)
            scrollView.addSubview(testView)
        }
    }
    
    func getGuestUserNameFromDefault() -> String {
        
        let defaults = UserDefaults.standard
        
        if(defaults.value(forKey: "guestName") == nil){
            
            return ""
            
        }
        else{
            
            return defaults.value(forKey: "guestName") as! String
            
        }
    }
    
    func getFromName() -> String {
        
        let defaults = UserDefaults.standard
        let isSessionMaintained: Bool = (defaults.value(forKey: "session") != nil)
        if isSessionMaintained == true {
            
            return (defaults.value(forKey: "name") as! String?)!
            
        }
        
        return ""
    }
    
    func editOrder(sender: UIButton){
        if didComeFromSummaryScreen==true{
            
            didComeFromSummaryScreen=false
            
        }
        
        if(UserDefaults.standard.value(forKey: "user_id") != nil){
            
            goToPackageDetailScreenLoginFlow()
            ViewController.editOrderBackPressed = true
            
        }
        else{
            
            goToPackageDetailScreen()
            
        }
    }
    
    func removePackage(sender: UIButton) {
        let alertController = UIAlertController(title: "Delete order", message: "Are you sure you want to delete the order?", preferredStyle:UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default)
        { action -> Void in
            
            if self.packages.count <= 1 {
                
                self.segmentSuperView.removeFromSuperview()
                self.segmentControl.removeFromSuperview()
                self.scrollView.removeFromSuperview()
                self.segmentSuperView = UIView()
                self.segmentControl.removeFromSuperview()
                self.scrollView = UIScrollView()
                self.items = []
                self.packages = []
                self.indexForPackage = -1
                self.bottomButton.setTitle("NEXT", for: .normal)
                self.addNewToButton.isHidden = true
                
            }
            else {
                self.items = []
                self.indexForPackage = -1
                self.packages.remove(at: sender.tag)
                self.totalPages = self.packages.count
                self.segmentControl.selectedSegmentIndex = HMSegmentedControlNoSegment
                UIView.animate(withDuration: 0.7, delay: 3.0, options: .curveEaseOut, animations: {
                    self.segmentControl.selectedSegmentIndex = HMSegmentedControlNoSegment
                }, completion: { finished in
                })
                
                self.scrollView.removeFromSuperview()
                self.scrollView = UIScrollView()
                self.createScrollView()
                self.configureScrollView()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    self.createSegmentControl()
                    self.updateDataOnDelete()
                    
                })
            }
            if(self.packages.count >= 1){
                self.toTextField.text = self.packages[0].toFromObj?.to
            }
            else{
                self.toTextField.text = ""
            }
            self.hideScheduleButtonIfAllPackagesDeleted()
        })
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel)
        { action -> Void in
            
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    func hideScheduleButtonIfAllPackagesDeleted() {
        
        if packages.count <= 0 {
            
            goToScheduleButton?.isHidden = true
            
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = floor(scrollView.contentOffset.x / UIScreen.main.bounds.size.width)
        if currentPage >= 0 {
            
            segmentControl.selectedSegmentIndex = Int(currentPage)
            self.indexForPackage = Int(currentPage)
            self.fromTextField.text = packages[Int(currentPage)].toFromObj?.from
            self.toTextField.text = packages[Int(currentPage)].toFromObj?.to
            
        }
    }
    
    
    //UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if(dropDownArray.count>0){
            
            return dropDownArray.count
            
        }
        else{
            
            return 0
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DropDownCell
        
        if isFirstResponse {
            
            cell.addressLabel.text = saveSearches[indexPath.row].address
            
        }
        else {
            
            if self.dropDownArray.count > indexPath.row {
                
                cell.addressLabel.text = dropDownArray[indexPath.row]
                
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFirstResponse {
            
            if self.isFirstTextField {
                
                currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude = Double(saveSearches[indexPath.row].longitude!)!
                currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude = Double(saveSearches[indexPath.row].latitute!)!
                
            }
            else {
                
                currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude = Double(saveSearches[indexPath.row].longitude!)!
                currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude = Double(saveSearches[indexPath.row].latitute!)!
                
            }
            let fancy = GMSCameraPosition.camera(withLatitude: Double(saveSearches[indexPath.row].latitute!)!,
                                                 longitude: Double(saveSearches[indexPath.row].longitude!)!, zoom: 14, bearing: 0, viewingAngle: 0)
            self.mapView_?.camera = fancy
        }
        else {
            
            moveMarker(row: indexPath.row)
            
        }
        
        visibleOrInvisibleDocumentButton()
        emptyAndReloadSearchTableView()
        
        dropDownTableView.isHidden = true
        
    }
    
    func moveMarker(row: Int) {
        
        let placesClient = GMSPlacesClient()
        placesClient.lookUpPlaceID(longLatSearchPlacesIDs[row], callback: { (place, error) -> Void in
            guard let place = place else {
                return
            }
            let fancy = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude,
                                                 longitude: place.coordinate.longitude, zoom: 14, bearing: 0, viewingAngle: 0)
            self.mapView_?.camera = fancy
            
            if self.isFirstTextField {
                
                self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude = place.coordinate.longitude
                self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude = place.coordinate.latitude
                self.fromTextField.text = place.name
                
            }
            else {
                
                self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude = place.coordinate.longitude
                self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude = place.coordinate.latitude
                self.toTextField.text = place.name
            }
        })
        
    }
    
    func emptyAndReloadSearchTableView() {
        
        self.dropDownArray = []
        self.dropDownTableView.reloadData()
        self.dropDownTableView.isHidden = true
        
    }
    
    func getSaveLocations() {
        let token = "gwMgjByDiM6yMX8aYgJb"
        let url = "http://ana-staging.ykptzambix.us-west-2.elasticbeanstalk.com/v1/user_get_location?user_id=\(String(describing: UserDefaults.value(forKey: "user_id")))&page=1"
        
        let manager = AFHTTPSessionManager()
        manager.requestSerializer.setValue(token, forHTTPHeaderField: "Authorization")
        manager.get(url, parameters: nil, progress: nil, success: { (requestOperation, response) in
            self.doesServerRespondForUserSavedSearches = true
            self.parse(response: response as! NSDictionary)
            
        }, failure: { (requestOperation, error) in
        })
    }
    
    func parse(response: NSDictionary) {
        let locationArray = response["locations"] as! NSArray
        for location in 0..<locationArray.count {
            let dic = locationArray[location] as! NSDictionary
            let address = dic["address"]
            let latitude = dic["latitude"]
            let longitude = dic["longitude"]
            let location_id = dic["location_id"]
            let name = dic["name"]
            let place_id = dic["place_id"]
            print("place ID NIL \(String(describing: place_id))")
            if String(describing: place_id!) == "<null>" {
                saveSearches.append(UserSaveSearches(address: address as! String, longitude: longitude as! String, latitute: latitude as! String, location_id: location_id as! Int, name: name as! String, placeID: -1))
            }
            else {
                saveSearches.append(UserSaveSearches(address: address as! String, longitude: longitude as! String, latitute: latitude as! String, location_id: location_id as! Int, name: name as! String, placeID: place_id as! Int))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if isLoadedFirstTime {
            isLoadedFirstTime = false
            if (manager.location?.coordinate) == nil {
                
            }
            else {
                getAddressFromGeocodeCoordinate(coordinate: (manager.location?.coordinate)!)
            }
        }
    }
    
    func currentLocationButtonAction(){
        
        if CLLocationManager.locationServicesEnabled() {
            if text_field_is_responder_location_should_work==true{
                isLoadedFirstTime = true
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.startUpdatingLocation()
                getAddressFromGeocodeCoordinate(coordinate: (locationManager.location?.coordinate)!)
                self.locationManager.stopUpdatingLocation()
            }
        }
        else{
            
            if let url = URL(string: "App-Prefs:root=LOCATION_SERVICES") {
                
                if #available(iOS 10.0, *) {
                    
                    UIApplication.shared.open(url, completionHandler: .none)
                    
                }
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        var ad = CLLocationCoordinate2D()
        if mapView_?.camera.target.latitude != nil || mapView_?.camera.target.longitude != nil {
            
            ad.latitude = (mapView_?.camera.target.latitude)!
            ad.longitude = (mapView_?.camera.target.longitude)!
            self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude = ad.latitude
            self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude = ad.longitude
            getAddress(coordinate: ad)
            self.geoFencingServerCall(lines: [""])
            
        }
    }
    
    //If location is off creat this UI
    func createUI() {
        location_is_offline=true
        let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(25.285805), longitude: CLLocationDegrees(51.532585), zoom: 12, bearing: 0, viewingAngle: 0)
        mapView_ = GMSMapView.map(withFrame: CGRect(x:0 , y:0 , width: self.view.frame.width , height: self.view.frame.height - 40), camera: camera)
        let currentLocationButton = UIButton(frame: CGRect(x:(mapView_?.frame.width)! - 50 , y: (mapView_?.frame.height)!/2 , width: 40 , height: 40))
        currentLocationButton.setImage(UIImage(named: "location"), for: .normal)
        currentLocationButton.addTarget(self, action: #selector(self.currentLocationButtonAction), for: .touchUpInside)
        mapView_?.addSubview(currentLocationButton)
        self.view.addSubview(mapView_!)
        mapView_?.delegate = self
        mapView_?.settings.consumesGesturesInView = false
        
        mapView_?.addSubview(contentView)
        contentView.keepTopInset.Equal = 0
        contentView.keepLeftInset.Equal = 0
        contentView.keepRightInset.Equal = 0
        contentView.keepHeight.Equal = 500
        contentView.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(topContentViewTapped))
        contentView.addGestureRecognizer(tap)
        
        
        mapView_?.addSubview(v)
        v.keepHeight.Equal = 30
        v.keepWidth.Equal = 30
        v.contentMode = .scaleAspectFill
        v.keepLeadingInset.Equal = (self.mapView_?.frame.width)!/2 - 15
        v.keepTopInset.Equal = (self.mapView_?.frame.height)!/2 - 30
        v.image = UIImage(named: "mapPin")
        
        // OpenSliderButton
        let sliderButton = UIButton()
        contentView.addSubview(sliderButton)
        sliderButton.keepTopInset.Equal = 19
        sliderButton.keepLeftInset.Equal = 20
        sliderButton.keepHeight.Equal = 40
        sliderButton.keepWidth.Equal = 40
        sliderButton.backgroundColor = UIColor.clear
        sliderButton.setImage(UIImage(named: "menudark"), for: .normal)
        sliderButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 20)
        sliderButton.addTarget(self, action: #selector(self.openLeftMenu), for: .touchUpInside)
        createBottomButton()
        
        
        if(packages.count < 1 ){
            
            contentView.addSubview(rightTopIntercomView)
            rightTopIntercomView.backgroundColor = UIColor.clear
            rightTopIntercomView.keepTopInset.Equal = 19
            rightTopIntercomView.keepRightInset.Equal = 20
            rightTopIntercomView.keepHeight.Equal = 50
            rightTopIntercomView.keepWidth.Equal = 30
            rightTopIntercomView.addSubview(rightSliderButton)
            rightTopIntercomView.addSubview(chatCountLbl)
            
            chatCountLbl.backgroundColor = UIColor.white
            chatCountLbl.textColor = Color.appColor
            chatCountLbl.keepTopInset.Equal = 0
            chatCountLbl.keepRightInset.Equal = 0
            chatCountLbl.keepHeight.Equal = 15
            chatCountLbl.keepWidth.Equal = 15
            chatCountLbl.layer.cornerRadius = 7.5
            chatCountLbl.layer.masksToBounds = true
            chatCountLbl.font = Constants().setBoldFont(Size: 8)
            chatCountLbl.textAlignment = .center
            updateUnreadCount()
            
            rightSliderButton.keepTopInset.Equal = 5
            rightSliderButton.keepRightInset.Equal = 0
            rightSliderButton.keepHeight.Equal = 30
            rightSliderButton.keepWidth.Equal = 30
            rightSliderButton.backgroundColor = UIColor.clear
            rightSliderButton.setImage(UIImage(named: "chat-1"), for: .normal)
            rightSliderButton.addTarget(self, action: #selector(self.openIntercomChat), for: .touchUpInside)
        }
        
        self.fromTextField.delegate = self
        self.toTextField.delegate = self
        self.fromTextField.tintColor = Constants().selectedColor
        self.toTextField.tintColor = Constants().selectedColor
        
        // fromSuperView
        contentView.addSubview(self.fromSuperView)
        self.fromSuperView.keepTopOffsetTo(sliderButton)?.Equal = 0
        self.fromSuperView.keepLeftInset.Equal = 10
        self.fromSuperView.keepRightInset.Equal = 10
        self.fromSuperView.keepHeight.Equal = 45
        self.fromSuperView.backgroundColor = UIColor.white
        highlightfromTextfield()
        
        //fromRemoveButton
        self.fromSuperView.addSubview(self.fromRemoveButton)
        fromRemoveButton.keepRightInset.Equal = 0
        fromRemoveButton.keepWidth.Equal = 40
        fromRemoveButton.keepHeight.Equal = 40
        fromRemoveButton.keepVerticallyCentered()
        fromRemoveButton.tag = 0
        fromRemoveButton.backgroundColor = UIColor.clear
        fromRemoveButton.setImage(UIImage(named: "remove"), for: .normal)
        fromRemoveButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13)
        fromRemoveButton.addTarget(self, action: #selector(self.clear(sender:)), for: .touchUpInside)
        fromRemoveButton.isHidden = true
        
        // FromTextField
        self.fromSuperView.addSubview(self.fromTextField)
        self.fromTextField.keepTopInset.Equal = 0
        self.fromTextField.tag = 1
        self.fromTextField.keepLeftInset.Equal = 30
        self.fromTextField.keepRightOffsetTo(self.fromRemoveButton)?.Equal = 10
        self.fromTextField.keepHeight.Equal = 40
        self.fromTextField.tintColor = Constants().selectedColor
        self.fromTextField.backgroundColor = UIColor.white
        if(didComeFromSummaryScreen){
            createBottomViewWithOrderToEdit()
            changeMarkerPosition()
        }
        else{
            
            self.geoFencingServerCall(lines: [""])
            
            if(!isGeoFenced){
                
                self.fromTextField.text = ""
                v.image = UIImage(named: "mapPin-1")
                
            }
            else{
                
                v.image = UIImage(named: "mapPin")
                
            }
        }
        
        self.fromTextField.textColor = UIColor.black
        self.fromTextField.font = UIFont(name: "Ubuntu", size: 13)!
        self.fromTextField.delegate = self
        fromTextField.returnKeyType = UIReturnKeyType.done
        
        let fromImageView = UIImageView()
        self.fromSuperView.addSubview(fromImageView)
        fromImageView.keepLeftInset.Equal = 8
        fromImageView.keepRightOffsetTo(fromTextField)?.Equal = 2
        fromImageView.keepTopInset.Equal = 8
        fromImageView.keepBottomInset.Equal = 8
        fromImageView.contentMode = .scaleAspectFit
        fromImageView.backgroundColor = UIColor.clear
        
        // toSuperView
        contentView.addSubview(self.toSuperView)
        self.toSuperView.keepTopOffsetTo(fromTextField)?.Equal = 5
        self.toSuperView.keepLeftInset.Equal = 10
        self.toSuperView.keepRightInset.Equal = 10
        self.toSuperView.keepHeight.Equal = 45
        self.toSuperView.backgroundColor = UIColor.white
        
        //toRemoveButton
        self.toSuperView.addSubview(toRemoveButton)
        toRemoveButton.keepRightInset.Equal = 0
        toRemoveButton.keepWidth.Equal = 40
        toRemoveButton.keepHeight.Equal = 40
        toRemoveButton.keepVerticallyCentered()
        toRemoveButton.tag = 1
        toRemoveButton.backgroundColor = UIColor.clear
        toRemoveButton.setImage(UIImage(named: "remove"), for: .normal)
        toRemoveButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13)
        toRemoveButton.addTarget(self, action: #selector(self.clear(sender:)), for: .touchUpInside)
        toRemoveButton.isHidden=true
        
        // ToButton
        self.toSuperView.addSubview(self.toTextField)
        self.toTextField.tag = 2
        self.toTextField.keepTopInset.Equal = 0
        self.toTextField.keepLeftInset.Equal = 30
        self.toTextField.keepRightOffsetTo(self.toRemoveButton)?.Equal = 10
        self.toTextField.keepHeight.Equal = 40
        self.toTextField.backgroundColor = UIColor.white
        self.toTextField.textColor = UIColor.black
        self.toTextField.font = UIFont(name: "Ubuntu", size: 13)!
        self.toTextField.tintColor = Constants().selectedColor
        self.toTextField.delegate = self
        self.toTextField.returnKeyType = UIReturnKeyType.done
        self.toTextField.adjustsFontSizeToFitWidth = true
        
        //from image view
        let fromToImageView2 = UIImageView()
        self.toSuperView.addSubview(fromToImageView2)
        fromToImageView2.keepLeftInset.Equal = 8
        fromToImageView2.keepRightOffsetTo(toTextField)?.Equal = 2
        fromToImageView2.keepTopInset.Equal = -32
        fromToImageView2.keepBottomInset.Equal = 18
        fromToImageView2.contentMode = .scaleAspectFit
        fromToImageView2.image = UIImage(named: "tofromTextField")
        fromToImageView2.backgroundColor = UIColor.clear
        
        //AddNewToButton
        contentView.addSubview(self.addNewToButton)
        self.addNewToButton.keepLeftInset.Equal = 20
        self.addNewToButton.keepWidth.Equal = UIScreen.main.bounds.width/10
        self.addNewToButton.keepHeight.Equal = UIScreen.main.bounds.width/10
        self.addNewToButton.keepTopOffsetTo(self.toSuperView)?.Equal = -((UIScreen.main.bounds.width/9)/3)
        addNewToButton.addTarget(self, action: #selector(self.addNew(sender:)), for: .touchUpInside)
        self.addNewToButton.backgroundColor = UIColor.clear
        self.addNewToButton.setBackgroundImage(UIImage(named: "addact"), for: .normal)
        self.addNewToButton.isHidden = true
        self.contentView.keepHeight.Equal = UIScreen.main.bounds.height/15 + UIScreen.main.bounds.width/20 + 5 + UIScreen.main.bounds.width/16 + 1 + UIScreen.main.bounds.height/16 + UIScreen.main.bounds.width/10
        
        if didComeFromSummaryScreen {
            
            configureScrollView()
            fillFieldsWithAddresses()
            addNewToButton.isHidden = false
            highlightToTextfield()
            
        }
    }
    
    //If location is On creat this UI
    func createUI(latitude: CLLocationDegrees, longitude: CLLocationDegrees, address: [String]) {
        location_is_offline=false
        let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude), zoom: 14, bearing: 0, viewingAngle: 0)
        mapView_ = GMSMapView.map(withFrame: CGRect(x:0 , y:0 , width: self.view.frame.width , height: self.view.frame.height - 40), camera: camera)
        mapView_?.isMyLocationEnabled = true
        let currentLocationButton = UIButton(frame: CGRect(x:(mapView_?.frame.width)! - 50 , y: (mapView_?.frame.height)!/2 , width: 40 , height: 40))
        currentLocationButton.setBackgroundColor(color: .white, forState: .normal)
        currentLocationButton.setImage(UIImage(named: "location"), for: .normal)
        currentLocationButton.addTarget(self, action: #selector(self.currentLocationButtonAction), for: .touchUpInside)
        mapView_?.addSubview(currentLocationButton)
        self.view.addSubview(mapView_!)
        mapView_?.delegate = self
        mapView_?.settings.consumesGesturesInView = false
        
        mapView_?.addSubview(contentView)
        contentView.keepTopInset.Equal = 0
        contentView.keepLeftInset.Equal = 0
        contentView.keepRightInset.Equal = 0
        contentView.keepHeight.Equal = 500
        contentView.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(topContentViewTapped))
        contentView.addGestureRecognizer(tap)
        
        
        mapView_?.addSubview(v)
        v.keepHeight.Equal = 30
        v.keepWidth.Equal = 30
        v.contentMode = .scaleAspectFill
        v.keepLeadingInset.Equal = (self.mapView_?.frame.width)!/2 - 15
        v.keepTopInset.Equal = (self.mapView_?.frame.height)!/2 - 30
        v.image = UIImage(named: "mapPin")
        
        // OpenSliderButton
        let sliderButton = UIButton()
        contentView.addSubview(sliderButton)
        sliderButton.keepTopInset.Equal = 19
        sliderButton.keepLeftInset.Equal = 20
        sliderButton.keepHeight.Equal = 40
        sliderButton.keepWidth.Equal = 40
        sliderButton.backgroundColor = UIColor.clear
        sliderButton.setImage(UIImage(named: "menudark"), for: .normal)
        sliderButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 20)
        sliderButton.addTarget(self, action: #selector(self.openLeftMenu), for: .touchUpInside)
        
        createBottomButton()
        
        
        if(packages.count < 1 ){
            
            contentView.addSubview(rightTopIntercomView)
            
            
            rightTopIntercomView.backgroundColor = UIColor.clear
            rightTopIntercomView.keepTopInset.Equal = 19
            rightTopIntercomView.keepRightInset.Equal = 20
            rightTopIntercomView.keepHeight.Equal = 50
            rightTopIntercomView.keepWidth.Equal = 30
            rightTopIntercomView.addSubview(rightSliderButton)
            rightTopIntercomView.addSubview(chatCountLbl)
            
            
            chatCountLbl.backgroundColor = UIColor.white
            chatCountLbl.textColor = Color.appColor
            chatCountLbl.keepTopInset.Equal = 0
            chatCountLbl.keepRightInset.Equal = 0
            chatCountLbl.keepHeight.Equal = 15
            chatCountLbl.keepWidth.Equal = 15
            chatCountLbl.layer.cornerRadius = 7.5
            chatCountLbl.layer.masksToBounds = true
            chatCountLbl.font = Constants().setBoldFont(Size: 8)
            chatCountLbl.textAlignment = .center
            updateUnreadCount()
            
            
            rightSliderButton.keepTopInset.Equal = 5
            rightSliderButton.keepRightInset.Equal = 0
            rightSliderButton.keepHeight.Equal = 30
            rightSliderButton.keepWidth.Equal = 30
            rightSliderButton.backgroundColor = UIColor.clear
            rightSliderButton.setImage(UIImage(named: "chat-1"), for: .normal)
            rightSliderButton.addTarget(self, action: #selector(self.openIntercomChat), for: .touchUpInside)
        }
        
        self.fromTextField.delegate = self
        self.toTextField.delegate = self
        
        // fromSuperView
        contentView.addSubview(self.fromSuperView)
        self.fromSuperView.keepTopOffsetTo(sliderButton)?.Equal = 0
        self.fromSuperView.keepLeftInset.Equal = 10
        self.fromSuperView.keepRightInset.Equal = 10
        self.fromSuperView.keepHeight.Equal = 45
        self.fromSuperView.backgroundColor = UIColor.white
        highlightfromTextfield()
        
        //fromRemoveButton
        self.fromSuperView.addSubview(self.fromRemoveButton)
        fromRemoveButton.keepRightInset.Equal = 0
        fromRemoveButton.keepWidth.Equal = 40
        fromRemoveButton.keepHeight.Equal = 40
        fromRemoveButton.keepVerticallyCentered()
        fromRemoveButton.tag = 0
        fromRemoveButton.backgroundColor = UIColor.clear
        fromRemoveButton.setImage(UIImage(named: "remove"), for: .normal)
        fromRemoveButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13)
        fromRemoveButton.addTarget(self, action: #selector(self.clear(sender:)), for: .touchUpInside)
        fromRemoveButton.isHidden=true
        
        // FromTextField
        self.fromSuperView.addSubview(self.fromTextField)
        self.fromTextField.keepTopInset.Equal = 0
        self.fromTextField.tag = 1
        self.fromTextField.keepLeftInset.Equal = 30
        self.fromTextField.keepRightOffsetTo(self.fromRemoveButton)?.Equal = 10
        self.fromTextField.keepHeight.Equal = 40
        self.fromTextField.tintColor = Constants().selectedColor
        self.fromTextField.backgroundColor = UIColor.white
        if(didComeFromSummaryScreen){
            
        }
        else{
            geoFencingServerCall(lines: address)
            if(!isGeoFenced){
                
                self.fromTextField.text = ""
                v.image = UIImage(named: "mapPin-1")
            }
            else{
                self.fromTextField.text = " \(address[0]) \(address[1])"
                v.image = UIImage(named: "mapPin")
                
                
            }
        }
        
        self.fromTextField.textColor = UIColor.black
        self.fromTextField.font = UIFont(name: "Ubuntu", size: 13)!
        self.fromTextField.delegate = self
        fromTextField.returnKeyType = UIReturnKeyType.done
        
        let fromImageView = UIImageView()
        self.fromSuperView.addSubview(fromImageView)
        fromImageView.keepLeftInset.Equal = 8
        fromImageView.keepRightOffsetTo(fromTextField)?.Equal = 2
        fromImageView.keepTopInset.Equal = 8
        fromImageView.keepBottomInset.Equal = 8
        fromImageView.contentMode = .scaleAspectFit
        fromImageView.backgroundColor = UIColor.clear
        
        // toSuperView
        contentView.addSubview(self.toSuperView)
        self.toSuperView.keepTopOffsetTo(fromTextField)?.Equal = 5
        self.toSuperView.keepLeftInset.Equal = 10
        self.toSuperView.keepRightInset.Equal = 10
        self.toSuperView.keepHeight.Equal = 45
        self.toSuperView.backgroundColor = UIColor.white
        
        //toRemoveButton
        self.toSuperView.addSubview(toRemoveButton)
        toRemoveButton.keepRightInset.Equal = 0
        toRemoveButton.keepWidth.Equal = 40
        toRemoveButton.keepHeight.Equal = 40
        toRemoveButton.keepVerticallyCentered()
        toRemoveButton.tag = 1
        toRemoveButton.backgroundColor = UIColor.clear
        toRemoveButton.setImage(UIImage(named: "remove"), for: .normal)
        toRemoveButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13)
        toRemoveButton.addTarget(self, action: #selector(self.clear(sender:)), for: .touchUpInside)
        toRemoveButton.isHidden=true
        
        // To Text Field
        self.toSuperView.addSubview(self.toTextField)
        self.toTextField.tag = 2
        self.toTextField.keepTopInset.Equal = 0
        self.toTextField.keepLeftInset.Equal = 30
        self.toTextField.keepRightOffsetTo(self.toRemoveButton)?.Equal = 10
        self.toTextField.keepHeight.Equal = 40
        self.toTextField.backgroundColor = UIColor.white
        self.toTextField.textColor = UIColor.black
        self.toTextField.font = UIFont(name: "Ubuntu", size: 13)!
        self.toTextField.tintColor = Constants().selectedColor
        self.toTextField.delegate = self
        self.toTextField.returnKeyType = UIReturnKeyType.done
        
        self.toTextField.adjustsFontSizeToFitWidth = true
        
        let fromToImageView2 = UIImageView()
        self.toSuperView.addSubview(fromToImageView2)
        fromToImageView2.keepLeftInset.Equal = 8
        fromToImageView2.keepRightOffsetTo(toTextField)?.Equal = 2
        fromToImageView2.keepTopInset.Equal = -32
        fromToImageView2.keepBottomInset.Equal = 18
        fromToImageView2.contentMode = .scaleAspectFit
        fromToImageView2.image = UIImage(named: "tofromTextField")
        fromToImageView2.backgroundColor = UIColor.clear
        
        //AddNewToButton
        contentView.addSubview(self.addNewToButton)
        self.addNewToButton.keepLeftInset.Equal = 20
        self.addNewToButton.keepWidth.Equal = UIScreen.main.bounds.width/10
        self.addNewToButton.keepHeight.Equal = UIScreen.main.bounds.width/10
        self.addNewToButton.keepTopOffsetTo(self.toSuperView)?.Equal = -((UIScreen.main.bounds.width/9)/3)
        addNewToButton.addTarget(self, action: #selector(self.addNew(sender:)), for: .touchUpInside)
        self.addNewToButton.backgroundColor = UIColor.clear
        self.addNewToButton.setBackgroundImage(UIImage(named: "addact"), for: .normal)
        self.addNewToButton.isHidden = true
        self.contentView.keepHeight.Equal = UIScreen.main.bounds.height/15 + UIScreen.main.bounds.width/20 + 5 + UIScreen.main.bounds.width/16 + 1 + UIScreen.main.bounds.height/16 + UIScreen.main.bounds.width/10
        
        
        if didComeFromSummaryScreen {
            
            configureScrollView()
            print("didComeFromSummaryScreen2 \(orderToEdit)")
            createBottomViewWithOrderToEdit()
            changeMarkerPosition()
            fillFieldsWithAddresses()
            addNewToButton.isHidden = false
            highlightToTextfield()
            
        }
    }
    
    func highlightfromTextfield() {
        
        isFirstTextField = true
        isSecondTextField = false
        
    }
    
    func highlightToTextfield() {
        
        isFirstTextField = false
        isSecondTextField = true
        
    }
    
    
    func changeMarkerPosition() {
        let fancy = GMSCameraPosition.camera(withLatitude: Double((self.packages[self.indexForPackage].toFromObj?.fromLat!)!),
                                             longitude: Double((self.packages[self.indexForPackage].toFromObj?.fromLong!)!),
                                             zoom: 14, bearing: 0, viewingAngle: 0)
        self.mapView_?.camera = fancy
    }
    
    func fillFieldsWithAddresses() {
        self.fromTextField.text = self.packages[self.indexForPackage].toFromObj?.from
        self.toTextField.text = self.packages[self.indexForPackage].toFromObj?.to
    }
    
    func createBottomViewWithOrderToEdit() {
        totalPages = packages.count
        indexForPackage = orderToEdit
        createSegmentSuperView()
        
        if goToScheduleButton == nil {
            
            createScheduleButton()
            
        }
        else {
            
            goToScheduleButton?.isHidden = false
            
        }
        
        changeSegmentPage()
        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        swipeUp(recognizer: bottomSwipe)
    }
    
    func changeSegmentPage() {
        
        var newFrame = scrollView.frame
        newFrame.origin.x = UIScreen.main.bounds.width * CGFloat(self.indexForPackage)
        DispatchQueue.main.async {
            let cg = CGPoint(x: newFrame.origin.x, y: 0)
            self.scrollView.setContentOffset(cg, animated: true)
        }
    }
    
    func addNew(sender: UIButton) {
        
        if didComeFromSummaryScreen==true{
            
            didComeFromSummaryScreen=false
            
        }
        if packages.count <= 2 {
            bottomButton.setTitle("NEXT", for: .normal)
            self.toTextField.text = ""
            indexForPackage = -1
            self.bottomButton.isEnabled = true
        }
        else {
            bottomButton.setTitle("SCHEDULE", for: .normal)
            let alert = Global.alertAction(title: "Order Limit", message: "Orders cannot be greater than 3")
            present(alert, animated: true, completion: nil)
        }
    }
    
    func openIntercomChat(){
        
        let when = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: when) {
            Intercom.presentMessenger()
        }
        
    }
    
    func openLeftMenu() {
        
        self.fromTextField.resignFirstResponder()
        self.toTextField.resignFirstResponder()
        self.slideMenuController()?.openLeft()
        
    }
    
    func getAddressFromGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { response , error in
            
            if response != nil {
                
                if let address = response!.firstResult() {
                    let lines = address.lines! as [String]
                    self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude = coordinate.latitude
                    self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude = coordinate.longitude
                    self.geoFencingServerCall(lines: lines)
                    self.createUI(latitude: (coordinate.latitude), longitude: (coordinate.longitude), address: lines)
                }
            }
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            
            fromSuperView.stopAnimating()
            toSuperView.stopAnimating()
            dropDownTableView.isHidden = true
            removebuttons()
            fromTextField.resignFirstResponder()
            toTextField.resignFirstResponder()
            
        }
        
        func getAddress(coordinate: CLLocationCoordinate2D) {
            
            let geocoder = GMSGeocoder()
            geocoder.reverseGeocodeCoordinate(coordinate) { response , error in
                if !ViewController.onPackageViewController {
                    if response != nil {
                        
                        if let address = response!.firstResult() {
                            
                            let lines = address.lines! as [String]
                            var addressCollection: String = ""
                            
                            for str in 0..<lines.count {
                                addressCollection = "\(addressCollection) \(lines[str])"
                            }
                            
                            if self.isFirstTextField {
                                if(self.isGeoFenced){
                                    
                                    if self.didComeFromSummaryScreen==false{
                                        self.fromTextField.text = "\(addressCollection)"
                                    }
                                    self.v.image = UIImage(named: "mapPin")
                                    self.fromTextField.resignFirstResponder()
                                    self.toTextField.becomeFirstResponder()
                                }
                                else{
                                    self.fromTextField.text = ""
                                    self.v.image = UIImage(named: "mapPin-1")
                                    self.fromTextField.resignFirstResponder()
                                    
                                    
                                }
                                if self.packages.count > 1
                                {
                                    if self.didComeFromSummaryScreen==false{
                                        
                                        self.packages[self.indexForPackage].toFromObj?.fromLong = coordinate.longitude
                                        self.packages[self.indexForPackage].toFromObj?.fromLat = coordinate.latitude
                                        self.packages[self.indexForPackage].toFromObj?.from = "\(addressCollection)"
                                    }
                                }
                                else {
                                    self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude = coordinate.latitude
                                    self.currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude = coordinate.longitude
                                }
                                self.changeFromAddressFromAllPackages(long: coordinate.longitude, lat: coordinate.latitude, address: addressCollection)
                            }
                            else {
                                
                                if self.didComeFromSummaryScreen==false{
                                    if(self.isGeoFenced){
                                        
                                        self.toTextField.text = "\(addressCollection)"
                                        self.v.image = UIImage(named: "mapPin")
                                        self.toTextField.resignFirstResponder()
                                        
                                    }
                                    else{
                                        
                                        self.toTextField.text = ""
                                        self.v.image = UIImage(named: "mapPin-1")
                                        self.toTextField.resignFirstResponder()
                                        
                                    }
                                }
                                
                            }
                            
                            if self.indexForPackage != -1 && self.indexForPackage < self.packages.count{
                                
                                if (self.didComeFromSummaryScreen == false){
                                    self.packages[self.indexForPackage].toFromObj?.toLong = coordinate.longitude
                                    self.packages[self.indexForPackage].toFromObj?.toLat = coordinate.latitude
                                    self.packages[self.indexForPackage].toFromObj?.to = "\(addressCollection)"
                                }
                                
                            }
                            else {
                                
                                self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude = coordinate.latitude
                                self.currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude = coordinate.longitude
                                
                            }
                            
                        }
                        if self.indexForPackage != -1 && self.indexForPackage < self.packages.count{
                            
                            let recentSelectedSegment = self.indexForPackage
                            self.refreshBottomSheet()
                            self.segmentControl.selectedSegmentIndex = recentSelectedSegment
                            
                        }
                        
                    }
                    self.visibleOrInvisibleDocumentButton()
                }
            }
        }
    }
}

func refreshBottomSheet() {
    if(self.didComeFromSummaryScreen){
        
        self.toTextField.text = self.packages[self.indexForPackage].toFromObj?.to
        
    }else{
        
        if(viewsInScrollView.count != 0){
            
            for i in 0 ..< viewsInScrollView.count {// i is index
                
                let fromAddress = viewsInScrollView[i].viewWithTag(2) as! UILabel
                fromAddress.text = "\((packages[i].toFromObj?.from!)!)"
                let toAddress = viewsInScrollView[i].viewWithTag(4) as! UILabel
                toAddress.text = "\((packages[i].toFromObj?.to!)!)"
                
            }
        }
    }
}

func changeFromAddressFromAllPackages(long: Double, lat: Double, address: String) {
    for i in 0..<packages.count {
        packages[i].toFromObj?.from = address
        packages[i].toFromObj?.fromLat = lat
        packages[i].toFromObj?.fromLong = long
    }
}

func clear(sender: UIButton!) {
    
    if sender.tag == 0 {
        
        if(packages.count > 1){
            let alertController = UIAlertController(title: "Warning", message: "Changing from location will change it for all orders", preferredStyle:UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel)
            { action -> Void in
                
                self.fromTextField.text = " "
                self.setPlaceHolderText()
                self.removebuttons()
            })
            alertController.addAction(UIAlertAction(title: "Cancel" , style: UIAlertActionStyle.destructive)
            { action -> Void in
                
            })
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            self.fromTextField.text = ""
            setPlaceHolderText()
            removebuttons()
            self.fromTextField.becomeFirstResponder()
        }
        
    }
    else {
        self.toTextField.text = ""
        removebuttons()
        self.toTextField.becomeFirstResponder()
    }
    visibleOrInvisibleDocumentButton()
}

func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 30
}

func showShadowAroundDropDownTableView() {
    
    Constants().setBorderColor(button: self.dropDownTableView)
    
}

func visibleOrInvisibleDocumentButton() {
    if (self.fromTextField.text?.characters.count)! > 0 && (self.toTextField.text?.characters.count)! > 0 {
        
        self.bottomButton.isEnabled = true
        
    }
    else {
        
        self.bottomButton.isEnabled = true
        
    }
}

func hideKeyboardAndDropDownTableView(sender: UITextField) {
    
    sender.resignFirstResponder()
    self.dropDownArray = []
    self.dropDownTableView.reloadData()
    dropDownTableView.isHidden = true
    
}

func goToPackageDetailScreenLoginFlow() {
    
    if indexForPackage != -1 {
        if(packages.count == 0){
            let toFromObj: ToFrom = ToFrom(to: toTextField.text!, toLat: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude, toLong: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude, from: fromTextField.text!, fromLat: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude, fromLong: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude)!
            let package: Package = Package(toFromObj: toFromObj)
            packages.append(package)
            indexForPackage = packages.count - 1
        }
    }
    
    if indexForPackage == -1 {
        let toFromObj: ToFrom = ToFrom(to: toTextField.text!, toLat: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude, toLong: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude, from: fromTextField.text!, fromLat: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude, fromLong: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude)!
        let package: Package = Package(toFromObj: toFromObj)
        packages.append(package)
        indexForPackage = packages.count - 1
    }
    else {
        if(packages.count > 0){
            if toTextField.text?.isEmpty==true{
                toTextField.text = " "
                toTextField.placeholder="Where To?"
            }
            if fromTextField.text?.isEmpty==true{
                fromTextField.text = " "
                fromTextField.placeholder="From"
            }
            
            let toFromObj: ToFrom = ToFrom(to: toTextField.text!, toLat: (packages[indexForPackage].toFromObj?.toLat)!, toLong: (packages[indexForPackage].toFromObj?.toLong)!, from: fromTextField.text!, fromLat: (packages[indexForPackage].toFromObj?.fromLat)!, fromLong: (packages[indexForPackage].toFromObj?.fromLong)!)!
            packages[indexForPackage].toFromObj = toFromObj
        }
    }
    ViewController.onPackageViewController = true
    SkyFloatingLabelTextField.isCenterAlign = false
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let mainViewController = storyboard.instantiateViewController(withIdentifier: "PackageDetailLoginFlowViewController") as! PackageDetailLoginFlowViewController
    if(packages.count > 0){
        mainViewController.package = packages[indexForPackage]
    }
    
    mainViewController.packagesCount = packages.count
    present(mainViewController, animated: true, completion: nil)
    
}

func goToPackageDetailScreen() {
    if indexForPackage != -1 {
        if(packages.count == 0){
            let toFromObj: ToFrom = ToFrom(to: toTextField.text!, toLat: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude, toLong: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude, from: fromTextField.text!, fromLat: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude, fromLong: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude)!
            let package: Package = Package(toFromObj: toFromObj)
            packages.append(package)
            indexForPackage = packages.count - 1
        }
    }
    
    if indexForPackage == -1 {
        let toFromObj: ToFrom = ToFrom(to: toTextField.text!, toLat: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.latitude, toLong: currentLongitudeLatitudeOfToFieldBeforeAddingOrder.longitude, from: fromTextField.text!, fromLat: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.latitude, fromLong: currentLongitudeLatitudeOfFromFieldBeforeAddingOrder.longitude)!
        let package: Package = Package(toFromObj: toFromObj)
        packages.append(package)
        indexForPackage = packages.count - 1
    }
    else {
        if(packages.count > 0){
            if toTextField.text?.isEmpty==true{
                toTextField.text = " "
                setPlaceHolderText()
            }
            if fromTextField.text?.isEmpty==true{
                fromTextField.text = " "
                setPlaceHolderText()
            }
            let toFromObj: ToFrom = ToFrom(to: toTextField.text!, toLat: (packages[indexForPackage].toFromObj?.toLat)!, toLong: (packages[indexForPackage].toFromObj?.toLong)!, from: fromTextField.text!, fromLat: (packages[indexForPackage].toFromObj?.fromLat)!, fromLong: (packages[indexForPackage].toFromObj?.fromLong)!)!
            packages[indexForPackage].toFromObj = toFromObj
        }
    }
    ViewController.onPackageViewController = true
    SkyFloatingLabelTextField.isCenterAlign = false
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let mainViewController = storyboard.instantiateViewController(withIdentifier: "PackageDetailViewController") as! PackageDetailViewController
    if(packages.count > 0){
        mainViewController.package = packages[indexForPackage]
    }
    mainViewController.packagesCount = packages.count
    present(mainViewController, animated: true, completion: nil)
    
}

override func viewDidDisappear(_ animated: Bool) {
    
    self.segmentSuperView.removeFromSuperview()
    self.segmentControl.removeFromSuperview()
    self.scrollView.removeFromSuperview()
    segmentSuperView = UIView()
    removebuttons()
    segmentControl = SegmentedControlExistingSegmentTapped()
    scrollView = UIScrollView()
    self.items = []
    
}


func trimString(string: String) -> String{
    
    let trimmed = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
    return trimmed
    
}

func removebuttons(){
    self.toRemoveButton.isHidden=true
    self.fromRemoveButton.isHidden=true
}

extension UIImage {
    
    func colored(with color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor);
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        context!.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
}

class SegmentedControlExistingSegmentTapped : HMSegmentedControl
{
    var oldValue : Int!
    
    override func touchesBegan( _ touches: Set<UITouch>, with event: UIEvent? )
    {
        self.oldValue = self.selectedSegmentIndex
        super.touchesBegan( touches , with: event )
    }
    
    override func touchesEnded( _ touches: Set<UITouch>, with event: UIEvent? )
    {
        super.touchesEnded( touches , with: event )
        
        if self.oldValue == self.selectedSegmentIndex
        {
            sendActions( for: .valueChanged )
        }
    }
}

