/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

/**
*  Shows user a confirmation statement and possibly savings as a reward for making an account. Finishes Login flow
*/
class LoginFinishViewController: LoyaltyUIViewController {
    
    /// Raw phone number string
    var rawPhoneNumber: String!
    /// Authenticated user
    var user: User!
    /// User stations
    var stations: [GasStation]!

    override func viewDidLoad() {
        super.viewDidLoad()

        //hide text alert if not already hidden
        MILFakeMessageAlertViewManager.sharedInstance.hide()
        
        //save user and stations
        UserDataManager.sharedInstance.currentUser = user
        UserDataManager.sharedInstance.currentUser.gasStations = stations
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissToMain(_ sender: AnyObject) {
        if sender.tag == 1 {
            dismiss()
        }else{
            dismiss()
        }
        
        
    }

    func dismiss() {

        if let nav = navigationController as? LoginNavController {
            nav.dismiss()
        }
    }

}
