//
//  PasswordViewController.swift
//  Password Keeper
//
//  Created by David Fisher on 4/11/18.
//  Copyright © 2018 David Fisher. All rights reserved.
//

import UIKit
import FoldingCell
import Material
import Firebase

class PasswordViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

  let kCloseCellHeight: CGFloat = 85
  let kOpenCellHeight: CGFloat = 240
  var cellHeights = [CGFloat]()
  var passwords = [Password]()
    
    var currentUserCollectionRef: CollectionReference!
    var passwordListener: ListenerRegistration!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var fab: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    setUpFab()
  }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (Auth.auth().currentUser == nil) {
            // Sign in
            Auth.auth().signInAnonymously { (user, error) in
                if (error == nil) {
                    print("You are now signed in using Anonymous auth. uid: \(user!.uid)")
                } else {
                    print("Error with anonymous auth: \(error!.localizedDescription)")
                    self.setupFirebaseObservers()
                }
            }
            
        } else {
            print("You are already signed in as: \(Auth.auth().currentUser!.uid)")
            self.setupFirebaseObservers()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        passwordListener.remove()
    }
    
    func setupFirebaseObservers() {
        guard let currentUser = Auth.auth().currentUser else { return }
        currentUserCollectionRef = Firestore.firestore().collection(currentUser.uid)
        
        // Temp test
//        print("Send a fake piece of data to learn about auth")
//        currentUserCollectionRef.addDocument(data: ["services": "Hardcoded service",
//                                                    "username": "fisherds",
//                                                    "password": "12345"])
        self.passwords.removeAll()
        passwordListener = currentUserCollectionRef.order(by: "service").addSnapshotListener({ (passwordSnapshot, error) in
            guard let snapshot = passwordSnapshot else {
                print("Error fetching passwords. \(error!.localizedDescription)")
                return
            }
            snapshot.documentChanges.forEach {(docChange) in
                if (docChange.type == .added) {
                    print("New password: \(docChange.document.data())")
                    self.passwordAdded(docChange.document)
                } else if (docChange.type == .modified) {
                    print("Modified password: \(docChange.document.data())")
                    self.passwordUpdated(docChange.document)
                } else if (docChange.type == .removed) {
                    print("Removed password: \(docChange.document.data())")
                    self.passwordRemoved(docChange.document)
                }
            }
            self.passwords.sort(by: { (p1, p2) -> Bool in
                return p1.service < p2.service
            })
            self.tableView.reloadData()
        })
    }
    
    func passwordAdded(_ document: DocumentSnapshot) {
        let newPassword = Password(documentSnapshot: document)
        passwords.append(newPassword)
        cellHeights.append(kCloseCellHeight)
    }
    
    func passwordUpdated(_ document: DocumentSnapshot) {
        let modifiedPassword = Password(documentSnapshot: document)
        for password in passwords {
            if (password.id == modifiedPassword.id) {
                password.service = modifiedPassword.service
                password.username = modifiedPassword.username
                password.password = modifiedPassword.password
                break
            }
        }
    }
    
    func passwordRemoved(_ document: DocumentSnapshot) {
        for i in 0 ..< passwords.count {
            if passwords[i].id == document.documentID {
                passwords.remove(at: i)
                cellHeights.remove(at: i)
                break
            }
        }
    }

  func setUpFab() {
    let img: UIImage? = UIImage(named: "ic_add_white")
    fab.backgroundColor = Color.indigo.base
    fab.tintColor = Color.white
    fab.setImage(img, for: .normal)
    fab.setImage(img, for: .highlighted)
  }

  // MARK: - Button Click Handlers


  func onEdit(pw : Password) {
    let alertController = UIAlertController(title: "Edit password", message: "", preferredStyle: .alert)
    alertController.addTextField { (textField) -> Void in
      textField.text = pw.service
      textField.placeholder = "Service"
    }
    alertController.addTextField { (textField) -> Void in
      textField.text = pw.username
      textField.placeholder = "Username"
    }
    alertController.addTextField { (textField) -> Void in
      textField.text = pw.password
      textField.placeholder = "Password"
      textField.isSecureTextEntry = true
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
    let defaultAction = UIAlertAction(title: "Edit", style: UIAlertActionStyle.default) { (action) -> Void in
      let serviceTextField = alertController.textFields![0]
      let usernameTextField = alertController.textFields![1]
      let passwordTextField = alertController.textFields![2]

      // Locally edit a Password and reload the table.
//      pw.service = serviceTextField.text!
//      pw.username = usernameTextField.text!
//      pw.password = passwordTextField.text!
//      self.tableView.reloadData()
        let editedPassword = Password(service: serviceTextField.text!,
                                      username: usernameTextField.text!,
                                      password: passwordTextField.text!)
        self.currentUserCollectionRef.document(pw.id!).updateData(editedPassword.data)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(defaultAction)
    present(alertController, animated: true, completion: nil)
  }

  func onDelete(pw : Password) {
    let alertController = UIAlertController(title: "Delete password", message: "Are you sure?", preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
    let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) { (action) -> Void in

      // Locally delete a Password and reload the table.
//      let indexPw: Int! = self.passwords.index(of: pw)
//      self.passwords.remove(at: indexPw)
//      self.cellHeights.remove(at: indexPw)
//      self.tableView.reloadData()
        self.currentUserCollectionRef.document(pw.id!).delete()
    }
    alertController.addAction(cancelAction)
    alertController.addAction(deleteAction)
    present(alertController, animated: true, completion: nil)
  }


  @IBAction func addPassword(_ sender: Any) {
    let alertController = UIAlertController(title: "Add password", message: "", preferredStyle: .alert)
    alertController.addTextField { (textField) -> Void in
      textField.placeholder = "Service"
    }
    alertController.addTextField { (textField) -> Void in
      textField.placeholder = "Username"
    }
    alertController.addTextField { (textField) -> Void in
      textField.placeholder = "Password"
      textField.isSecureTextEntry = true
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
    let defaultAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (action) -> Void in
      let serviceTextField = alertController.textFields![0]
      let usernameTextField = alertController.textFields![1]
      let passwordTextField = alertController.textFields![2]

      // Locally add a Password and reload the table.
      let newPassword = Password(service: serviceTextField.text!,
                                 username: usernameTextField.text!,
                                 password: passwordTextField.text!)
//      self.passwords.insert(newPassword, at: 0)
//      self.cellHeights.insert(self.kCloseCellHeight, at: 0)
//      self.tableView.reloadData()
        self.currentUserCollectionRef.addDocument(data: newPassword.data)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(defaultAction)
    present(alertController, animated: true, completion: nil)
  }

  // MARK: - Table View Methods

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return passwords.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PasswordCell", for: indexPath)

    if let passwordCell = cell as? PasswordCell {
      passwordCell.bindPassword(passwords[indexPath.row])
      passwordCell.editPasswordHandler = onEdit
      passwordCell.deletePasswordHandler = onDelete
    }
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return cellHeights[indexPath.row]
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath) as! FoldingCell

    var duration = 0.0
    if cellHeights[indexPath.row] == kCloseCellHeight { // open cell
      cellHeights[indexPath.row] = kOpenCellHeight
      cell.openAnimation(nil)
      duration = 0.5
    } else {// close cell
      cellHeights[indexPath.row] = kCloseCellHeight
      cell.closeAnimation(nil)
      duration = 1.1
    }

    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
      tableView.beginUpdates()
      tableView.endUpdates()
    }, completion: nil)
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let foldingCell = cell as? FoldingCell {
      if cellHeights[indexPath.row] == kCloseCellHeight {
        foldingCell.unfold(false, animated: false, completion:nil)
      } else {
        foldingCell.unfold(true, animated: false, completion: nil)
      }
    }
  }

}
