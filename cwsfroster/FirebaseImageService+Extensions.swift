//
//  FirebaseImageService+Extensions.swift
//  rollcall
//
//  Created by Bobby Ren on 9/10/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Balizinha

extension FirebaseImageService {
    enum RollCallImageType: String, CustomStringConvertible {
        var description: String {
            rawValue
        }

        case member
        case organization
    }
}
