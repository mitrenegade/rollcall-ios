//
//  String+Utils.swift
//  rollcall
//
//  Created by Bobby Ren on 2/7/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension String {
    func attributedString(_ substring: String, size: CGFloat) -> NSAttributedString? {
        let attributes: [NSAttributedString.Key: AnyObject] = [.foregroundColor: UIColor.white,
                                                               .font: UIFont.systemFont(ofSize: size)]
        
        let attributedString = NSMutableAttributedString(string: self, attributes: attributes)
        let range = (self as NSString).range(of: substring)

        attributedString.addAttributes([.foregroundColor: UIColor.darkGray], range: range)
        
        return attributedString
    }
    
    func isValidEmail() -> Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
//        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        // http://emailregex.com/
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }
}
