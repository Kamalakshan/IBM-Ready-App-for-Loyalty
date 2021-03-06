/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

/**
*  Requests phone number from user to send an SMS message containing an account confirmation number.
*/
class LoginViewController: UIViewController {
    
    /// Navigation portion of Login View Controller
    @IBOutlet weak var navView: UIView!
    /// Label to display error message if login is incorrect or invalid
    @IBOutlet weak var loginErrorLabel: UILabel!
    /// View containing alert saying invalid number was entered
    @IBOutlet weak var invalidNumberView: UIView!
    /// UITextField to contain user's phone number
    @IBOutlet weak var phoneNumberTextField: UITextField!
    /// AppDelegate for the application
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    /// Phone number utility class
    let phoneUtil = NBPhoneNumberUtil.sharedInstance()
    /// Error pointer for phone number utility
    var errorPointer:NSError?
    /// Receive code button
    @IBOutlet weak var receiveCodeButton: UIButton!
    /// Raw phone number string
    var rawPhoneNumber: String!
    /// Boolean of whether or not demo mode is set, auto logging the user in
    var demoMode: Bool = false
    /// Key for the login phone number, matching the key in the json backend
    let loginPhoneNumberKey = "5128675309"
    let logger : OCLogger = OCLogger.getInstanceWithPackage("Loyalty");
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPlaceholderText()
        invalidNumberView.isHidden = true //hide alert initially
        
        //recognize taps to dismiss keyboard
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(LoginViewController.didTapView))
        self.view.addGestureRecognizer(tapRecognizer)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        phoneNumberTextField.becomeFirstResponder()
        showDemoModeAlert()
    }
    
    /**
    Method to ask user if he or she wants to enter demo mode, auto logging the user in
    */
    func showDemoModeAlert() {
        let demoAlert = UIAlertController(title: NSLocalizedString("Demo Mode",comment: ""), message: NSLocalizedString("Would you like to use Roadrunner in demo mode?",comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        demoAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel",comment: ""), style: .default, handler: { (action: UIAlertAction) in
            self.demoMode = false
        }))
        demoAlert.addAction(UIAlertAction(title: NSLocalizedString("OK",comment: ""), style: .default, handler: { (action: UIAlertAction) in
            self.demoMode = true
            self.retryRequest()
        }))
        present(demoAlert, animated: true, completion: nil)
    }
    
    /**
    Method called when user taps "receive code" to initiate MFP Resource request
    
    - parameter sender: sending object
    */
    @IBAction func tappedReceiveCode(_ sender: AnyObject) {
        //MFP Resource Request to get User data from JSON
        phoneNumberTextField.resignFirstResponder()
        retryRequest()
    }
    
    @IBAction func tappedLoginWithTwitter(_ sender: AnyObject) {
        let alertView = UIAlertController(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Syncing with Twitter not currently supported", comment: ""), preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(alertView, animated: true, completion: nil)
        
        // Simulate user being synced with Twitter
        let user = UserDataManager.sharedInstance.currentUser
        user?.syncedWithTwitter = true
    }
    
    
    /**
    Method to retry MFP Resource request
    */
    func retryRequest() {
        self.phoneNumberTextField.resignFirstResponder()
        MILLoadViewManager.sharedInstance.show()
        if (!demoMode) {
            UserDataManager.sharedInstance.getUserData(rawPhoneNumber, callback: gotUserData) //number for testing: 5128675309
        } else {
            UserDataManager.sharedInstance.getUserData("5128675309", callback: gotUserData) //log in for demo mode
        }
    }
    
    /**
    Callback method called when the UserDataManager returns a result
    
    - parameter data: data returned from UserDataManager
    */
    func gotUserData(_ data: [String : AnyObject]) {
        MILLoadViewManager.sharedInstance.hide()
        if let failString = data["failure"] as? String { //failure of some kind
            if (failString == "no connection") { //failure -- no connection
                
                logger.logInfoWithMessages(message:"FAILURE NO CONNECTION - \(data)")
                MILAlertViewManager.sharedInstance.show(NSLocalizedString("Network Error", comment: ""), view: self.view, underView: self.navView, toHeight: 20, callback: retryRequest)
            } else if (failString == "unknown user") { //failure -- unknown user
                phoneNumberTextField.becomeFirstResponder()
                MILAlertViewManager.sharedInstance.hide() //hide alert if shown
                logger.logInfoWithMessages(message:"FAILURE UNKNOWN USER - \(data)")
                //phoneNumberTextField.text = ""
                phoneNumberTextField.becomeFirstResponder()
                invalidNumberView.isHidden = false
            }
        } else { //success! (no failure string)
            MILAlertViewManager.sharedInstance.hide() //hide alert if shown
           
            logger.logInfoWithMessages(message:"User Data Received: \(data)")
            let currentStations = UserDataManager.sharedInstance.currentUser.gasStations
            let user = User(json: data)
            
            //now move to next VC if not in demo mode
            if (!demoMode) {
                let destinationVC = self.storyboard?.instantiateViewController(withIdentifier: "second") as! LoginConfirmationViewController
                destinationVC.phoneNumberString = phoneNumberTextField.text
                destinationVC.rawPhoneNumber = rawPhoneNumber
                destinationVC.user = user
                destinationVC.stations = currentStations
                self.navigationController?.pushViewController(destinationVC, animated: true)
            } else {
                UserDataManager.sharedInstance.currentUser = user
                UserDataManager.sharedInstance.currentUser.gasStations = currentStations
                
                self.dismissToMain(self)
            }
            
        }
    }
    
    
    
    @IBAction func dismissToMain(_ sender: AnyObject) {

        if let nav = navigationController as? LoginNavController {
            phoneNumberTextField.resignFirstResponder()
            nav.dismiss()
        }
    }
    
    /**
    Method called to dismiss keyboard when gesture recognizer recognizes a tap in the view
    */
    func didTapView(){
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
    Method to set the style and attributes of the phoneNumberTextField placeholder text
    */
    func setPlaceholderText() {
        //set color of placeholder text
        let textFieldAttributes : Dictionary = [NSForegroundColorAttributeName: UIColor.grayLoyalty()]
        let phoneAttributedString = NSAttributedString(string: phoneNumberTextField.placeholder!, attributes: textFieldAttributes)
        phoneNumberTextField.attributedPlaceholder = phoneAttributedString
        phoneNumberTextField.tintColor = UIColor.blackLoyalty() //black text cursor
        receiveCodeButton.isUserInteractionEnabled = false //disable initially
        receiveCodeButton.setBackgroundColorForState(UIColor.grayLoyalty(), forState: UIControlState())
        
        
    }
    
    
    
    
    
}

extension LoginViewController: UITextFieldDelegate {
    
    /**
    Method to restrict phoneNumberTextField to numerical characters and format like a phone number, ie (123)456-7890
    
    - parameter textField: text field in question
    - parameter range:     range of characters to be changed
    - parameter string:    replacement string
    
    - returns: boolean representing whether or not the change will be made
    */
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        if textField == phoneNumberTextField
        {
            //Remove non-numeric characters from phone number
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            let decimalString = components.joined(separator: "")
            
            rawPhoneNumber = decimalString
            
            //Format the string based on the user's current locale
            let locale = Locale.current
            let countryCode = (locale as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String
            let formatter = NBAsYouTypeFormatter(regionCode: countryCode)
            let formattedString = formatter?.inputString(decimalString)
            
            //Parse the string and if it's a valid number, remove focus from text field
            do {
                let number:NBPhoneNumber = try phoneUtil!.parse(decimalString, defaultRegion:countryCode)
                if (phoneUtil?.isValidNumber(forRegion: number, regionCode: countryCode))! || decimalString == loginPhoneNumberKey{ //enable button and hide keyboard
                    phoneNumberTextField.resignFirstResponder()
                    receiveCodeButton.isUserInteractionEnabled = true
                    loginErrorLabel.text = NSLocalizedString("Incorrect login!", comment: "")
                    invalidNumberView.isHidden = true
                    receiveCodeButton.setBackgroundColorForState(UIColor.purpleLoyalty(), forState: UIControlState())
                } else { //disable
                    receiveCodeButton.isUserInteractionEnabled = false
                    receiveCodeButton.setBackgroundColorForState(UIColor.grayLoyalty(), forState: UIControlState())
                    loginErrorLabel.text = NSLocalizedString("Invalid number!", comment: "")
                    invalidNumberView.isHidden = false
                }
            } catch let error as NSError {
                errorPointer = error
            }
            //Set the text field to the formatted value
            textField.text = formattedString
            return false
        }
        else
        {
            return true
        }
    }
    
    
}
