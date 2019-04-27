//
//  CustomInputAccessoryView.swift
//  wyd
//
//  Created by Jason Ellul on 2018-10-20.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit

private let defaultIcon = #imageLiteral(resourceName: "default.png")
private let heartIcon = #imageLiteral(resourceName: "heart.png")
private let starIcon = #imageLiteral(resourceName: "star.png")
private let fireIcon = #imageLiteral(resourceName: "fire.png")
private let moneyIcon = #imageLiteral(resourceName: "money-bag.png")
private let beerIcon = #imageLiteral(resourceName: "beer.png")
private let wineIcon = #imageLiteral(resourceName: "wine.png")
private let coffeeIcon = #imageLiteral(resourceName: "coffee-cup.png")
private let cutleryIcon = #imageLiteral(resourceName: "cutlery.png")
private let musicIcon = #imageLiteral(resourceName: "music note.png")
private let ballIcon = #imageLiteral(resourceName: "basketball.png")


protocol CustomInputAccessoryDelegate {
    func postComment(text: String)
    func textViewStartedEditing()
    func textViewEndedEditing()
}
protocol CustomInputAccessoryInLocationViewDelegate {
    func postMotive(text: String)
    func iconChanged()
}

// https://stackoverflow.com/questions/25816994/changing-the-frame-of-an-inputaccessoryview-in-ios-8/32647908#32647908
class CustomInputAccessoryView: UIView, UITextViewDelegate {
    
    var inChooseLocationView: Bool = false
    var iconMenuAnimating: Bool = false
    var iconMenuChoice: Int = 1
    var customInputAccessoryDelegate: CustomInputAccessoryDelegate?
    var customInputAccesoryInLocationViewDelegate: CustomInputAccessoryInLocationViewDelegate?
    var previousHeight: CGFloat = 0
    var placeholderText: String = "Spill the tea..."
    let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.backgroundColor = UIColor.white
        return view
    }()
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  20
        return imageView
    }()
    let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.textColor = UIColor.black
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.text = "Spill the tea..."
        textView.textAlignment = .left
        textView.backgroundColor = UIColor.clear
        textView.keyboardType = UIKeyboardType.twitter
        textView.textColor = .lightGray
        return textView
    }()
    let textPadding: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.layer.cornerRadius = 20
        view.layer.borderColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1.0).cgColor
        view.layer.borderWidth = 1
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    let postButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        button.titleLabel?.textAlignment = NSTextAlignment.left
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    let iconMenu: UIView = {
        let view = UIView(frame: CGRect(x: 64, y: 0, width: 40, height: 40))
        view.backgroundColor = UIColor.white
        view.layer.borderColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1.0).cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
        return view
        
    }()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.backgroundColor = UIColor.clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    override var intrinsicContentSize: CGSize {
        // Calculate intrinsicContentSize that will fit all the text
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        if inChooseLocationView {
            return CGSize(width: bounds.width, height: max(textSize.height + 64, 104))
        } else {
            return CGSize(width: bounds.width, height: max(textSize.height + 20, 60))
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        // This is required to make the view grow vertically
        autoresizingMask = .flexibleHeight
        // set initial previous height
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        previousHeight = textSize.height
        // Disabling textView scrolling prevents some undesired effects,
        // like incorrect contentOffset when adding new line,
        // and makes the textView behave similar to Apple's Messages app
        textView.isScrollEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        backgroundView.frame = CGRect(x: 0, y: 0, width: frame.width, height: 60)
        if inChooseLocationView {
            backgroundView.frame = CGRect(x: 0, y: 44, width: frame.width, height: 60)
        }
        self.addSubview(backgroundView)
        self.bringSubview(toFront: backgroundView)
        // add grey line on the top of bottom view
        let greyLineView = UIView()
        greyLineView.translatesAutoresizingMaskIntoConstraints = false
        greyLineView.backgroundColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1.0)
        backgroundView.addSubview(greyLineView)
        greyLineView.topAnchor.constraint(equalTo: backgroundView.topAnchor).isActive = true
        greyLineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        greyLineView.widthAnchor.constraint(equalToConstant: backgroundView.frame.width).isActive = true
        greyLineView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        // add profile image View
        backgroundView.addSubview(profileImageView)
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        profileImageView.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 12).isActive = true
        // add text padding
        textPadding.backgroundColor = UIColor.white
        textPadding.frame = CGRect(x: 64, y: 10, width: backgroundView.frame.width - 76, height: 40)
        textPadding.bounds = CGRect(x: 0, y: 0, width: textPadding.frame.width, height: textPadding.frame.height)
        backgroundView.addSubview(textPadding)
        // add textview to the padding
        textView.text = placeholderText
        textView.frame = CGRect(x: 5, y: 2, width: textPadding.frame.width - 57, height: textPadding.frame.height - 4)
        textPadding.addSubview(textView)
        // add postButton to the padding
        textPadding.addSubview(postButton)
        postButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        postButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        postButton.rightAnchor.constraint(equalTo: textPadding.rightAnchor).isActive = true
        postButton.centerYAnchor.constraint(equalTo: textPadding.centerYAnchor).isActive = true
        textView.delegate = self
        postButton.addTarget(self, action: #selector(postButtonPressed(_:)), for: .touchUpInside)

    }
    
    func addIconBar() {
        // create icon menu
        iconMenu.frame = CGRect(x: 0, y: 4, width: self.frame.width, height: 40)
        self.addSubview(iconMenu)
        // scrollview which contains all of the buttons
        scrollView.frame = CGRect(x: 0, y: 0, width: iconMenu.frame.width, height: iconMenu.frame.height)
        scrollView.contentSize = CGSize(width: 445, height: iconMenu.frame.height)
        iconMenu.addSubview(scrollView)
        
        let button1 = UIButton(frame: CGRect(x: 5, y: 0, width: 40, height: 40))
        button1.translatesAutoresizingMaskIntoConstraints = true
        button1.backgroundColor = UIColor.white
        button1.layer.cornerRadius = 5
        button1.setTitle("", for: .normal)
        button1.setImage(defaultIcon, for: .normal)
        button1.setImage(defaultIcon, for: .highlighted)
        button1.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button1.tag = 1
        button1.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button1)
        let button2 = UIButton(frame: CGRect(x: 45, y: 0, width: 40, height: 40))
        button2.translatesAutoresizingMaskIntoConstraints = true
        button2.backgroundColor = UIColor.white
        button2.layer.cornerRadius = 5
        button2.setTitle("", for: .normal)
        button2.setImage(starIcon, for: .normal)
        button2.setImage(starIcon, for: .highlighted)
        button2.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button2.tag = 2
        button2.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button2)
        let button3 = UIButton(frame: CGRect(x: 85, y: 0, width: 40, height: 40))
        button3.translatesAutoresizingMaskIntoConstraints = true
        button3.backgroundColor = UIColor.white
        button3.layer.cornerRadius = 5
        button3.setTitle("", for: .normal)
        button3.setImage(heartIcon, for: .normal)
        button3.setImage(heartIcon, for: .highlighted)
        button3.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button3.tag = 3
        button3.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button3)
        let button4 = UIButton(frame: CGRect(x: 125, y: 0, width: 40, height: 40))
        button4.translatesAutoresizingMaskIntoConstraints = true
        button4.backgroundColor = UIColor.white
        button4.layer.cornerRadius = 5
        button4.setTitle("", for: .normal)
        button4.setImage(fireIcon, for: .normal)
        button4.setImage(fireIcon, for: .highlighted)
        button4.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button4.tag = 4
        button4.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button4)
        let button5 = UIButton(frame: CGRect(x: 165, y: 0, width: 40, height: 40))
        button5.translatesAutoresizingMaskIntoConstraints = true
        button5.backgroundColor = UIColor.white
        button5.layer.cornerRadius = 5
        button5.setTitle("", for: .normal)
        button5.setImage(moneyIcon, for: .normal)
        button5.setImage(moneyIcon, for: .highlighted)
        button5.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button5.tag = 5
        button5.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button5)
        let button6 = UIButton(frame: CGRect(x: 205, y: 0, width: 40, height: 40))
        button6.translatesAutoresizingMaskIntoConstraints = true
        button6.backgroundColor = UIColor.white
        button6.layer.cornerRadius = 5
        button6.setTitle("", for: .normal)
        button6.setImage(beerIcon, for: .normal)
        button6.setImage(beerIcon, for: .highlighted)
        button6.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button6.tag = 6
        button6.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button6)
        let button7 = UIButton(frame: CGRect(x: 245, y: 0, width: 40, height: 40))
        button7.translatesAutoresizingMaskIntoConstraints = true
        button7.backgroundColor = UIColor.white
        button7.layer.cornerRadius = 5
        button7.setTitle("", for: .normal)
        button7.setImage(wineIcon, for: .normal)
        button7.setImage(wineIcon, for: .highlighted)
        button7.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button7.tag = 7
        button7.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button7)
        let button8 = UIButton(frame: CGRect(x: 285, y: 0, width: 40, height: 40))
        button8.translatesAutoresizingMaskIntoConstraints = true
        button8.backgroundColor = UIColor.white
        button8.layer.cornerRadius = 5
        button8.setTitle("", for: .normal)
        button8.setImage(coffeeIcon, for: .normal)
        button8.setImage(coffeeIcon, for: .highlighted)
        button8.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button8.tag = 8
        button8.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button8)
        let button9 = UIButton(frame: CGRect(x: 325, y: 0, width: 40, height: 40))
        button9.translatesAutoresizingMaskIntoConstraints = true
        button9.backgroundColor = UIColor.white
        button9.layer.cornerRadius = 5
        button9.setTitle("", for: .normal)
        button9.setImage(cutleryIcon, for: .normal)
        button9.setImage(cutleryIcon, for: .highlighted)
        button9.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button9.tag = 9
        button9.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button9)
        let button10 = UIButton(frame: CGRect(x: 365, y: 0, width: 40, height: 40))
        button10.translatesAutoresizingMaskIntoConstraints = true
        button10.backgroundColor = UIColor.white
        button10.layer.cornerRadius = 5
        button10.setTitle("", for: .normal)
        button10.setImage(musicIcon, for: .normal)
        button10.setImage(musicIcon, for: .highlighted)
        button10.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button10.tag = 10
        button10.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button10)
        let button11 = UIButton(frame: CGRect(x: 405, y: 0, width: 40, height: 40))
        button11.translatesAutoresizingMaskIntoConstraints = true
        button11.backgroundColor = UIColor.white
        button11.layer.cornerRadius = 5
        button11.setTitle("", for: .normal)
        button11.setImage(ballIcon, for: .normal)
        button11.setImage(ballIcon, for: .highlighted)
        button11.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button11.tag = 11
        button11.addTarget(self, action: #selector(self.iconSelected(_:)), for: .touchUpInside)
        scrollView.addSubview(button11)

        print (self.frame.debugDescription)
    }
    
    // icon was selected from icon bar
    @objc func iconSelected(_ sender: UIButton) {
        print (sender.tag)
        iconMenuChoice = sender.tag
        customInputAccesoryInLocationViewDelegate?.iconChanged()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // remove placeholder
        if (textView.text == placeholderText && textView.textColor == .lightGray) {
            textView.text = ""
            textView.textColor = .black
        }
        customInputAccessoryDelegate?.textViewStartedEditing()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        // add placeholder
        if (textView.text == "") {
            textView.text = placeholderText
            textView.textColor = .lightGray
        }
        customInputAccessoryDelegate?.textViewEndedEditing()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let estimatedHeight = textSize.height
        if estimatedHeight > previousHeight {
            let makeBiggerValue = estimatedHeight - previousHeight
            self.frame.size.height = self.frame.height + makeBiggerValue
            self.frame.origin.y = self.frame.origin.y - makeBiggerValue
            backgroundView.frame.size.height = backgroundView.frame.height + makeBiggerValue
            self.textPadding.frame.size.height = self.textPadding.frame.height + makeBiggerValue
            self.textView.frame.size.height = self.textView.frame.height + makeBiggerValue
            previousHeight = estimatedHeight
            self.invalidateIntrinsicContentSize()
            print (makeBiggerValue)
        } else if estimatedHeight < previousHeight {
            // make smaller
            let makeSmallerValue = previousHeight - estimatedHeight
            self.frame.size.height = self.frame.height - makeSmallerValue
            self.frame.origin.y = self.frame.origin.y + makeSmallerValue
            backgroundView.frame.size.height = backgroundView.frame.height - makeSmallerValue
            self.textPadding.frame.size.height = self.textPadding.frame.height - makeSmallerValue
            self.textView.frame.size.height = self.textView.frame.height - makeSmallerValue
            previousHeight = estimatedHeight
            print (makeSmallerValue)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxLength = 160
        let currentText = textView.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: text)
        if prospectiveText == "" || prospectiveText == "\n"{
            postButton.isEnabled = false
            postButton.alpha = 0.5
            
        } else {
            postButton.isEnabled  = true
            postButton.alpha = 1.0
        }
        if prospectiveText.contains("\n") { return false }
        return prospectiveText.count < maxLength
    }
    
    
    @objc func postButtonPressed(_ sender: Any) {
        if inChooseLocationView {
            customInputAccesoryInLocationViewDelegate?.postMotive(text: textView.text)
        } else {
            customInputAccessoryDelegate?.postComment(text: textView.text)
        }
        // reset post button and bottom view
        textView.text = ""
        textView.textColor = .black
        self.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 60)
        if inChooseLocationView {
            backgroundView.frame = CGRect(x: 0, y: 44, width: frame.width, height: 60)
        } else {
            backgroundView.frame = CGRect(x: 0, y: 0, width: frame.width, height: 60)
        }
        self.textPadding.frame = CGRect(x: 64, y: 10, width: self.frame.width - 76, height: 40)
        self.textView.frame = CGRect(x: 5, y: 2, width: self.textPadding.frame.width - 57, height: self.textPadding.frame.height - 4)
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        previousHeight = textSize.height
        self.invalidateIntrinsicContentSize()
        postButton.isEnabled = false
        postButton.alpha = 0.5
    }

    

}
