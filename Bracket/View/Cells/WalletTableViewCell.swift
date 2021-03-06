//
//  WalletTableViewCell.swift
//  Bracket
//
//  Created by Joseph Brownfield on 6/26/18.
//  Copyright © 2018 Joseph Brownfield. All rights reserved.
//

import UIKit
import CoreData

struct APIKeyValues {
    var exchange: Exchanges?
    var apiKey: String?
    var secretKey: String?
}

protocol WalletTableCellDelegate {
    func displayAlert(title: String, message: String)
    func localUpdateApiArray(apiKey: APIKeyValues)
    func reloadPortfolio()
    func reloadWallets(_ reload: Bool)
}

class WalletTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    var delegate: WalletTableCellDelegate?
    
    var apiKeyValue: APIKeyValues? {
        didSet {
            exchgLabel.text = apiKeyValue?.exchange?.rawValue
            apiKeyTextField.text = apiKeyValue?.apiKey
            secretTextField.text = apiKeyValue?.secretKey
            saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        }
    }
    
    @objc func saveButtonPressed(_ sender: UIButton) {
        print(sender)
        guard apiKeyTextField.text != "", secretTextField.text != "", apiKeyValue?.exchange != nil, let exchg = apiKeyValue?.exchange, let apiKeyText = apiKeyTextField.text, let secretText = secretTextField.text else {
            delegate?.displayAlert(title: "Incorrect Information", message: "Please enter a value for the key and the secret key.")
            return
        }
        
        guard (checkAndUpdateKey(exchg, apiKeyText, secretText)) == false else {
            delegate?.localUpdateApiArray(apiKey: APIKeyValues(exchange: exchg, apiKey: apiKeyText, secretKey: secretText))
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let keyEntity = NSEntityDescription.entity(forEntityName: "ExchgKeys", in: managedContext)!
        
        let key1 = NSManagedObject(entity: keyEntity, insertInto: managedContext)
        key1.setValue(exchg.rawValue, forKey: "exchange")
        key1.setValue(apiKeyText, forKey: "apiKey")
        key1.setValue(secretText, forKey: "secret")
        
        do {
            try managedContext.save()
            delegate?.localUpdateApiArray(apiKey: APIKeyValues(exchange: exchg, apiKey: apiKeyText, secretKey: secretText))
        } catch let error as NSError {
            print(error)
        }
    }
    
    func checkAndUpdateKey(_ exchg: Exchanges, _ apiKeyText: String, _ secretText: String) -> Bool {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let keyFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ExchgKeys")
        keyFetch.predicate = NSPredicate(format: "exchange = %@", exchg.rawValue)
        do {
            let keys = try managedContext.fetch(keyFetch)
            if keys.isEmpty {
                return false
            }
            for key in keys {
                print(key)
                let keyValue = key as! ExchgKeys
                keyValue.setValue(apiKeyText, forKey: "apiKey")
                keyValue.setValue(secretText, forKey: "secret")
                do {
                    try managedContext.save()
                    return true
                } catch let error as NSError {
                    print(error)
                    return false
                }
            }
            return true
        } catch let error as NSError {
            print(error)
            return true
        }
    }
    
    let exchgLabel = GenericLabel("KuCoin Keys", .left, fontBold(20), MainPageOptions().labelColor)
    
    let saveButton = GenericButton(title: "Save", radius: 3, color: MainPageOptions().darkGreen, font: fontLight(15))
    
    let apiKeyTextField: UITextField = {
        let textField = GenericNumTextField("API Key", .center, fontLight(15))
        textField.isSecureTextEntry = true
        return textField
    }()
    
    let secretTextField: UITextField = {
        let textField = GenericNumTextField("Secret Key", .center, fontLight(15))
        textField.isSecureTextEntry = true
        return textField
    }()
    
    func setupViews() {
        addSubview(exchgLabel)
        addSubview(apiKeyTextField)
        addSubview(secretTextField)
        addSubview(saveButton)
        
        let screenWidth = UIScreen.main.bounds.width
        let fieldSize = Int(screenWidth - 84)
        
        setupViewConstraints(format: "H:|-10-[v0(150)]", views: exchgLabel)
        for arrayView in [apiKeyTextField, secretTextField] {
            setupViewConstraints(format: "H:|-10-[v0(" + "\(fieldSize)" + ")]", views: arrayView)
        }
        
        setupViewConstraints(format: "V:|-10-[v0(20)]-10-[v1(30)]-10-[v2(30)]", views: exchgLabel, apiKeyTextField, secretTextField)
        
        setupViewConstraints(format: "H:[v0(50)]-12-|", views: saveButton)
        setupViewConstraints(format: "V:[v0]-27-[v1]-27-|", views: exchgLabel, saveButton)
        
        //secretTextField.centerYAnchor.constraint(equalTo: apiKeyTextField.centerYAnchor, constant: 1).isActive = true
        //saveButton.heightAnchor.constraint(equalTo: apiKeyTextField.heightAnchor, multiplier: 1).isActive = true
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class WalletHeaderCell: WalletTableViewCell {
    let headerLabel = GenericLabel("Important Information:", .left, fontBold(20), MainPageOptions().labelColor)
    let headerSection = UITextView(font: fontRegular(12), textColor: MainPageOptions().labelColor)
    
    override func setupViews() {
        addSubview(headerLabel)
        addSubview(headerSection)
        setupViewConstraints(format: "H:|-10-[v0]-5-|", views: headerLabel)
        setupViewConstraints(format: "H:|-5-[v0]-5-|", views: headerSection)
        setupViewConstraints(format: "V:|-10-[v0(20)]-5-[v1]-5-|", views: headerLabel, headerSection)
    }
}

class AddWalletCell: WalletTableViewCell {
    
    let ethplorer = Ethplorer()
    
    override func setupViews() {
        
        apiKeyTextField.isSecureTextEntry = false
        
        addSubview(exchgLabel)
        addSubview(apiKeyTextField)
        addSubview(saveButton)
        
        exchgLabel.text = "Wallet"
        apiKeyTextField.placeholder = "Wallet Address"
        
        backgroundColor = MainPageOptions().backgroundColor
        
        let screenWidth = UIScreen.main.bounds.width
        let fieldSize = Int(screenWidth - 84)
        
        setupViewConstraints(format: "H:|-10-[v0(150)]", views: exchgLabel)
        setupViewConstraints(format: "H:|-10-[v0(" + "\(fieldSize)" + ")]", views: apiKeyTextField)
        
        
        setupViewConstraints(format: "V:|-10-[v0(20)]-10-[v1(30)]", views: exchgLabel, apiKeyTextField)
        
        setupViewConstraints(format: "H:[v0(50)]-12-|", views: saveButton)
        setupViewConstraints(format: "V:[v0]-10-[v1(30)]", views: exchgLabel, saveButton)
        
        saveButton.addTarget(self, action: #selector(saveWalletPressed), for: .touchUpInside)
        
    }
    
    @objc func saveWalletPressed(_ sender: UIButton) {
        guard apiKeyTextField.text != "", let walletAddress = apiKeyTextField.text else {
            delegate?.displayAlert(title: "Incorrect Information", message: WalletSaveErrors.empty.rawValue)
            return
        }
        
        ethplorer.getEthWalletBalance(address: walletAddress) { (results, error) in
            DispatchQueue.main.async {
                guard let results = results, !(results.error) else {
                    self.delegate?.displayAlert(title: "Incorrect Wallet Address", message: WalletSaveErrors.incorrect.rawValue)
                    return
                }
                let (success, message) = self.saveWalletInfo(address: walletAddress)
                let title: String = success ? "Success" : "Error"
                if title == "Success" {
                    DispatchQueue.main.async {
                        self.delegate?.reloadWallets(true)
                        self.delegate?.reloadPortfolio()
                    }
                }
                self.delegate?.displayAlert(title: title, message: message.rawValue)
            }
            
        }
        
    }
    
    func saveWalletInfo(address: String) -> (Bool, WalletSaveErrors) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return (false, .genericError) }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let keyFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Wallets")
        keyFetch.predicate = NSPredicate(format: "address = %@", address)
        do {
            let keys = try managedContext.fetch(keyFetch)
            if keys.isEmpty {
                let entity = NSEntityDescription.entity(forEntityName: "Wallets", in: managedContext)
                let keyValue = NSManagedObject(entity: entity!, insertInto: managedContext)
                keyValue.setValue(address, forKey: "address")
                do {
                    try managedContext.save()
                    return (true, .success)
                } catch let error as NSError {
                    print(error)
                    return (false, .genericError)
                }
            } else {
                return (false, .duplicate)
            }
        } catch let error as NSError {
            print(error)
            return (false, .genericError)
        }
    }
    
}
