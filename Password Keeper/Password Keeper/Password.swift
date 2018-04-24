//
//  Password.swift
//  Password Keeper
//
//  Created by David Fisher on 4/11/18.
//  Copyright © 2018 David Fisher. All rights reserved.
//

import UIKit
import Firebase

class Password: NSObject {
    var id: String?
  var service: String
  var username: String
  var password: String
    
    let serviceKey = "service"
    let usernameKey = "username"
    let passwordKey = "password"

  init(service: String, username: String, password: String) {
    self.service = service
    self.username = username
    self.password = password
  }
    
    init(documentSnapshot: DocumentSnapshot) {
        self.id = documentSnapshot.documentID
        let data = documentSnapshot.data()!
        if data[serviceKey] != nil {
            self.service = data[serviceKey] as! String
        } else {
            self.service = ""
        }
        if data[usernameKey] != nil {
            self.username = data[usernameKey] as! String
        } else {
            self.username = ""
        }
        if data[passwordKey] != nil {
            self.password = data[passwordKey] as! String
        } else {
            self.password = ""
        }
    }
    
    var data: [String: Any] {
        return [serviceKey: self.service,
                usernameKey: self.username,
                passwordKey: self.password]
    }

}
