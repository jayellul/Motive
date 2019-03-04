//
//  EULAViewController.swift
//  wyd
//
//  Created by Jason Ellul on 2019-03-03.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit

class EULAViewController: UIViewController {
    
    // ui kit objects
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = "Motive End User License Agreement"
        label.numberOfLines = 0
        return label
    }()
    
    let EULALabel: UITextView = {
        let label = UITextView()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 16)
        label.isScrollEnabled = false
        label.text = "Thank you for your interest in Motive's social network services. This Social Network User Agreement (\"Agreement\") between you and Motive, Inc. (\"Motive\") governs your use of various services, applications and/or games that Motive may make available via Facebook (collectively, the \"Service\"). By using the Service, you agree to be bound by this Agreement on behalf of yourself and, if you are under the age of 18, on your behalf by your parent or legal guardian. Once you agree, you will be contractually bound to the terms below, which shall govern all aspects of your use of the Game. No one under the age of 13 may use the Service. You must also comply with Facebook's terms of use.\n" +
            "1. LICENSE TO USE THE SERVICE\n" +
            "Subject to your acceptance of this Agreement, Motive directly grants you a non-exclusive, non-transferable, revocable limited license to use and display the Service and related software (excluding source and object code) for your personal, non-commercial use.\n" +
            "2. LICENSE LIMITATIONS\n" +
            "The Service is a carefully controlled environment designed to provide the maximum level of enjoyment for all players. In order to preserve an enjoyable experience for all users, and to protect the intellectual property rights of Motive, the activities identified in this Section 2 (\"License Limitations\") are strictly prohibited and violate the conditions or limitations on your license to use the Service. Therefore, any use of the Service in violation of such restrictions exceeds the scope of the License granted to you and constitutes infringement of your license, and is grounds for immediate revocation of your license with or without any prior notice from Motive to you. Use of the Service in excess of these provisions, or use at all after your license is revoked, infringes Motive's or its licensor's copyrights and other intellectual property rights subsisting in and relating to the Service.\n" +
            "Violating these License Limitations may result in the suspension or permanent banning of your account, or such other lesser measures described in Section 3 which Motive may take in its sole discretion, or an action for copyright infringement or other legal claims, all of which are reserved. You agree that offering or providing banned services as described in this Section 2 and Section 3 to other players of the Service constitutes improper interference with Motive's contracts with such players, and Motive reserves the right to take formal legal action against you if you do so, without warning.\n" +
            "2.1 Cheating and Botting. You may not create or use any cheats, bots, automation software, hacks, mods or any other unauthorized software designed to modify the Service. In addition, you may not take advantage of Service system bugs or exploits.\n" +
            "2.2 Commercial Use. You may not exploit the Service for any commercial purpose (for example, advertising any product or service in-game, or use by the operator of a cyber café) without Motive's prior written consent.\n" +
            "2.3 Private Servers. You may not create, operate, participate in or use any unauthorized servers intended to emulate the Service.\n" +
            "2.4 Data Mining. You may not intercept, mine or otherwise collect information from the Service using unauthorized third party software.\n" +
            "2.5 Hacking and Circumvention. You may not hack, disassemble, decompile, or otherwise modify the Service or server computer code in any way, except as expressly permitted by Motive or applicable law.\n" +
            "2.6 Modifying or Creating Derivative Software. You may not modify or cause to be modified any files that are a part of the Service in any way not expressly authorized by Motive, and may not make any derivative works of the Service.\n" +
            "2.7 Commercial Spamming/Spimming. You may not use (or abuse) any chat and message services to distribute advertisements.\n" +
            "3. PROHIBITED ACTIVITIES\n" +
            "In addition to the License Limitations, there are other activities that you are forbidden from doing in connection with the Service (\"Prohibited Activities\"). In its discretion, Motive may use a variety of methods to deal with violations of this Agreement and the Prohibited Activities, including, but not limited to, any of the following:\n" +
            "Issuing a warning;\n" +
            "Removing or deleting ill-gotten in-Service items or currency;\n" +
            "Temporarily suspending an account;\n" +
            "Permanently terminating an account;\n" +
            "Permanently banning your IP address, residential address, or credit card number;\n" +
            "Asserting a lawsuit for breach of contract, copyright infringement, or other cause of action as may be applicable; and or\n" +
            "Seeking injunctive relief in any court or jurisdiction to prevent you from continuing such activity.\n" +
            "In addition, Motive shall be entitled to terminate any account (immediately and without notice) of any person who (1) was previously suspended or terminated by Motive and who Motive believes (in its sole discretion) re-registered using different registration information in order to circumvent or bypass such suspension or termination, or (2) Motive believes (in its sole discretion, based upon any information available, including registration and account information) that such person is enabling or assisting anyone else to conduct any Prohibited Activities of any kind.\n" +
            "The Prohibited Activities are as follows:\n" +
            "3.1 Sharing Account Information. You may not share your account or login information with anyone except as permitted by the Facebook terms of use.\n" +
            "3.2 Disruption. You may not in any way disrupt or interfere with the Service experience of other players, including the disruption of Motive's computers and servers.\n" +
            "3.3 Profanity and Offensive Language. You may not use profanity or any language that a reasonable person would find offensive obscene or otherwise improper, as determined by Motive in its sole discretion. The Service is for players aged 13 and older. You agree to behave accordingly.\n" +
            "\n" +
            "3.5 Naming Right. You may not use any name or other intellectual property belonging to Motive or any other third party in your use of the Service (for example, naming a character after a celebrity, company, product, or superhero).\n" +
            "3.6 Any Illegal Activities. You may not conduct any illegal activities whatsoever in connection with the Service. This includes every illegal activity not specifically highlighted above, including without limitation copyright infringement, trademark infringement, gambling, defamation, harassment, and fraud.\n" +
            "3.7 False Account Information. If applicable, you may not provide Motive with false information during the registration process.\n" +
            "3.8 Chargebacks. You are authorizing all fees charged under this Agreement. Therefore, you may not falsely notify your credit card or debit card provider that you did not authorize a charge. If you are using a parent's credit card, you must have their authorization to do so.\n" +
            "3.9 Non-Commercial Spamming/Spimming. You may not use (or abuse) the Service to harass other players.\n" +
            "4. OWNERSHIP\n" +
            "Motive (and, to the extent applicable, its licensors) owns and shall retain all right, title and interest in and to the Service, and will be the sole owner of any and all data you generate through your use of the Service, including but not limited to accounts, character attributes, statistics and assets. Motive owns all computer code, titles, themes, objects, characters, character names, animations, processes, likenesses, musical compositions and recordings, storylines, environments, buildings, artwork, sounds, and other intellectual property contained within the Service. You receive only those limited rights to access and use the Service set forth herein.\n" +
            "PLEASE READ CAREFULLY: YOU DO NOT OWN YOUR GAME ACCOUNT OR CHARACTER, OR HAVE ANY PROPERTY RIGHTS TO YOUR CHARACTER OR ITS VIRTUAL ASSETS OR DATA, ALL OF WHICH YOU AGREE ARE MONETARILY WITHOUT VALUE. YOU MAY NOT SELL, RENT, OR REPRODUCE ANY CHARACTER OR ANY VIRTUAL ASSETS ASSOCIATED WITH SUCH CHARACTER OR WITH ANY ACCOUNT CONTROLLED BY YOU FOR ANY COMMERCIAL PURPOSE. IF YOU DO SO, THIS LICENSE IS IMMEDIATELY TERMINATED.\n" +
            "5. REDEEMABLE POINT SYSTEM\n" +
            "5.1 Introduction to Redeemable Points. The Service may include a redeemable point system featuring redeemable points (\"Redeemable Points\") that may be used to obtain certain virtual products and services offered by Motive. Redeemable Points may be called different names in different games, but this Agreement will apply to all Redeemable Points offered by Motive.\n" +
            "5.2 Redeemable Points are Merely Licensed Virtual Goods and Have No Monetary Value. Redeemable Points are virtual goods licensed directly to you and owned at all times by Motive. Redeemable Points have no monetary value, and you do not have any personal property rights in Redeemable Points. Therefore, you may not trade Redeemable Points for cash, currency or any form of property, license or rights except for the virtual products and services that Motive chooses to offer in its sole discretion. You may not transfer Redeemable Points to any other person or entity or receive Redeemable Points from any other person or entity for any reason.\n" +
            "5.3 Limits on Redeemable Points. In order to protect your security and to deter fraud, Motive may impose limits on the amount of Redeemable Points that you may license per transaction and per month. Motive may also limit the maximum amount of Redeemable Points that you may hold in your account at any one time.\n" +
            "5.4 Usage of Redeemable Points. You may redeem Redeemable Points for certain virtual products and/or online services offered directly to the public by Motive. Motive reserves the right to adjust the amount of Redeemable Points due for each product and online service at any time, in its sole discretion, without notice. Once redeemed, Redeemable Points will be deducted from your account balance and cannot be used again. You have no right to reverse a transaction once it is completed. However, if Motive determines that an incorrect price (in Redeemable Points) is identified for a product or online service, it reserves the right to reverse and/or nullify any such transaction.\n" +
            "5.5 No Cash Refunds. Except as required by law, you have no right to receive a cash refund for unused Redeemable Points.\n" +
            "\n" +
            "5.7 Management of Redeemable Points. You agree that Motive has the absolute right to manage, modify, regulate and control any Redeemable Point system in its sole discretion. If Motive suspects any fraudulent, abusive or unlawful activity with respect to Redeemable Points, or any violation of this Agreement, then Motive may reduce or liquidate your Redeemable Points, or deactivate, suspend or terminate your access to the Service. Motive will not be liable to you or any third party for exercising these rights.\n" +
            "5.8 Redeemable Points and Virtual Goods Waiver. BY ACCEPTING THIS AGREEMENT OR USING THE SERVICE, YOU AGREE NOT TO ASSERT OR BRING ANY CLAIM OR SUIT AGAINST Motive, ITS AFFILIATES, ITS BACK-END SERVICE PROVIDERS, OR THEIR EMPLOYEES, ARISING OUT OF OR RELATED TO REDEEMABLE POINTS OR VIRTUAL GOODS, INCLUDING BUT NOT LIMITED TO ANY CLAIM WHICH IS BASED ON A THEORY THAT YOU \"OWN\" REDEEMABLE POINTS OR ANY VIRTUAL GOODS IN ANY GAME OR SERVICE OFFERED BY Motive OR ITS AFFILIATES, OR THAT YOU LOST THE \"VALUE\" OF VIRTUAL GOODS OR REDEEMABLE POINTS AS A RESULT OF DELETION OR ACCOUNT TERMINATION BY Motive, OR FOR ANY MODIFICATIONS IN THE AMOUNT OF REDEEMABLE POINTS REQUIRED TO ACCESS CERTAIN GOODS OR SERVICES, OR THE REMOVAL OF ACCESS TO ANY GOODS/SERVICES, OR FOR ANY MALFUNCTIONS AND/OR \"BUGS\" IN Motive'S GOODS AND SERVICES, INCLUDING A REDEEMABLE POINT SYSTEM.\n" +
            "6. RIGHT TO CHANGE OR TERMINATE THE SERVICE\n" +
            "The Service is provided by Motive for so long as Motive wishes to operate the Service in its sole discretion. The Service may be modified, suspended or restricted by Motive at any time without liability to you. Further, the Service may be terminated or otherwise discontinued by Motive with sixty (60) days prior notice without liability to you.\n" +
            "7. PRIVACY AND USE OF INFORMATION\n" +
            "By using the Service, you agree to Motive's Privacy Policy, which is incorporated into this Agreement by reference and is available at https://www.freeprivacypolicy.com/privacy/view/4ae74a3598ee061263609b56f4b61f27. The Privacy Policy governs how Motive will use and share your information, except as modified herein. You agree that Motive may use the information you provide (such as IP address or e-mail address) in order to identify you and contact you to deliver notices, and may send you product-related marketing information. You acknowledge that Motive will be monitoring your use of the Service to help you play the Service, for our internal analysis to help us improve our Services and services, to investigate disruptive activities or Prohibited Activities, and to confirm that you are abiding by the terms of this Agreement and related agreements. In order to protect Motive's staff and customers, Motive may cooperate with federal, state and local law enforcement with or without the receipt of a formal subpoena or search warrant. You acknowledge and consent that Motive may provide your electronic communications and data, including e-mails and chat logs if applicable, to such government authorities, without any liability to you or any third party. You hereby provide your consent to such actions.\n" +
            "8. GENERAL TERMS\n" +
            "8.1 Indemnification. You agree to indemnify and hold harmless Motive and its parent, subsidiaries, affiliates, partners, officers, employees and agents from any claim, demand, or loss (including reasonable attorney's fees and court costs) incurred due to your usage of the Service, your engagement in Prohibited Activities, and/or arising out of or related to content you submit, post, link to, transmit, or make available through the Service, your violation of this Agreement, or your violation of any rights of another User.\n" +
            "8.2 Disclaimer of Warranties. EXCEPT AS OTHERWISE EXPRESSLY PROVIDED IN THIS AGREEMENTTO THE MAXIMUM EXTENT PERMITTED BY LAW, (A) Motive EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, REGARDING THE SERVICE, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT OF THIRD PARTY INTELLECTUAL PROPERTY RIGHTS AND OTHER RIGHTS; AND (B) Motive IS MAKING THE SERVICE AVAILABLE \"AS IS\" WITHOUT ANY FURTHER WARRANTIES OR REPRESENTATIONS OF ANY KIND. YOU ASSUME THE RISK OF ANY AND ALL DAMAGE OR LOSS FROM USE OF, OR INABILITY TO USE, THE SERVICE. Motive DOES NOT WARRANT THAT THE SERVICE WILL MEET YOUR REQUIREMENTS OR THAT THE OPERATION OF THE SERVICE WILL BE UNINTERRUPTED OR ERROR-FREE.\n" +
            "8.3 Informal Dispute Resolution. It is Motive's goal to informally resolve legitimate consumer disputes without resort to formal litigation. Therefore, prior to filing any formal legal action against Motive, you agree to make a good faith attempt to informally resolve your grievance by sending a detailed letter with current contact information by Registered Mail or Overnight Delivery to the Motive, Inc. Legal Department, 999 North Sepulveda Blvd., 3rd Floor, El Segundo, CA 90245 USA. You agree to allow Motive thirty (30) days to contact you to attempt to resolve the dispute. If you file a formal legal action without abiding by this section and the action is unsuccessful, you agree that you will be responsible for Motive's costs and reasonable attorney's fees incurred as a result of the unsuccessful action.\n" +
            "8.4 Limited Liability/Remedy. TO THE MAXIMUM EXTENT PERMITTED BY LAW, Motive AND/OR ITS AFFILIATES HAVE NO LIABILITY TO YOU WHATSOEVER, AND IN NO EVENT WILL Motive AND/OR ANY OF ITS PARENT, SUBSIDIARY, OR AFFILIATED COMPANIES BE LIABLE FOR DAMAGES OF ANY KIND (INCLUDING, BUT NOT LIMITED TO, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, LOST PROFITS, OR LOST DATA, REGARDLESS OF THE FORESEEABILITY OF THOSE DAMAGES), ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, YOUR USE OF THE SERVICE OR OTHER MATERIALS PROVIDED TO YOU BY Motive, REGARDLESS OF THE LEGAL THEORY. UNDER NO CIRCUMSTANCES WILL Motive BE LIABLE TO YOU FOR MORE THAN THE AMOUNT OF MONEY YOU HAVE SPENT THROUGH THE SERVICE, WHICH SHALL BE YOUR SOLE AND EXCLUSIVE REMEDY.\n" +
            "8.5 Injunctive Relief. In no event will you be entitled to obtain any injunctive relief or otherwise enjoin, restrain, or otherwise interfere with Motive or with the distribution, operation, development, or performance of the Service or any related products or services.\n" +
            "8.6 Choice of Law and Venue. This Agreement and all actions arising out of or related to your use of the Service or this Agreement shall be governed by and construed in accordance with the laws of the State of California, excluding its choice of law provisions. Any actions arising out of or related to your use of the Service or this Agreement shall be heard in the courts located within Toronto, Ontario, Canada. Motive makes no representation that the Service is appropriate or available in other locations. The information provided on the Service is not intended for distribution to or use by any person or entity in any jurisdiction or country where such distribution or use would be contrary to law or regulation or which would subject Motive to any registration requirement within such jurisdiction or country. Accordingly, those persons who choose to access the Service from other locations do so on their own initiative and are solely responsible for compliance with local laws, if and to the extent local laws are applicable. Further, no software from this Service may be accessed, downloaded, exported or re-exported (i) into (or to a national or resident of) People's Republic of China, Cuba, Iraq, North Korea, Iran, Syria, or any other country to which the United States has embargoed goods; or (ii) to anyone on the U.S. Treasury Department's list of Specially Designated Nationals or the U.S. Commerce Department's Table of Deny Orders. By downloading any software or using the Service, you represent and warrant that you are not located in, under the control of, or a national or resident of, any such country or on any such list.\n" +
            "8.7 User Disputes. You shall be solely responsible for resolving any and all disputes that may arise between you and other players in connection with the Service, and for paying any and all expenses incurred by you in connection with resolving such dispute. Motive shall not be responsible for mediating or resolving any such disputes and shall have no liability to you or to any third party for any costs, fees, expenses, damages or other losses incurred in connection with or as a result of any such disputes.\n" +
            "8.8 Severability. If any sentence or any provision of this Agreement is determined by any court of competent jurisdiction to be invalid or unenforceable, such sentence or provision will be interpreted to the maximum extent to which it is valid and enforceable, all as determined by such court in such action, and the remaining sentences and provisions of this Agreement will, nevertheless, continue in full force and effect without being impaired or invalidated in any way.\n" +
            "8.9 No Waiver. No waiver by Motive of any term, provision or condition of this Agreement shall be deemed to be or construed as a waiver of any other term, provision or condition of this Agreement. No Motive customer service representative or any other personnel of Motive who interacts with you is legally empowered to bind Motive to any amendment or waiver of the terms of this Agreement.\n" +
            "8.10 Assignment. Motive shall have the right to assign and/or delegate in its sole discretion its rights and obligations under this Agreement in whole or in part to a third party at any time without notice to players. Each player's rights are personal to such player and may not be assigned.\n" +
            "8.11 Entire Agreement. This Agreement, together with the Privacy Policy, and any other terms of use relevant to your use of the Service, constitutes the entire understanding and agreement between the parties with respect to your use of the Service and supersedes any and all prior or contemporaneous oral or written communications with respect to the subject matter hereof, all of which are merged herein.\n" +
        "8.12 Changes to this Agreement. Motive reserves the right, at its sole discretion, to change, modify, add to, supplement or delete any of the terms and conditions of this Agreement or the way that the Service operates at any time. Motive will notify you of any such material changes in one of the following ways at its sole discretion: through email, website posting, pop-up screen or in-Service notice. If you do not agree to any such change or modification, you may terminate this Agreement by quitting the Service. Your continued use of the Service following any revision to this Agreement will demonstrate your full acceptance of any and all such changes.\n"
        return label
    }()
    
    let topBackButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Go Back", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        return button
    }()
    
    let backButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red:1.00, green:0.60, blue:0.20, alpha:1.0), for: .normal)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1.5
        return button
    }()
    
    func setupSubviews() {
        addGradientToView(view)
        
        if let textSize = EULALabel.text?.height(withConstrainedWidth: scrollView.frame.width - 32, font: UIFont.systemFont(ofSize: 16)) {

            self.scrollView.frame.size.width = self.view.frame.size.width
            self.scrollView.contentSize = CGSize(width: view.frame.size.width, height: textSize + 200)
            self.scrollView.showsVerticalScrollIndicator = true
            
            self.scrollView.addSubview(titleLabel)
            titleLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 30).isActive = true
            titleLabel.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 16).isActive = true
            titleLabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
            titleLabel.heightAnchor.constraint(equalToConstant: 60).isActive = true
            
            self.scrollView.addSubview(EULALabel)
            EULALabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 80).isActive = true
            EULALabel.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 16).isActive = true
            EULALabel.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
            EULALabel.heightAnchor.constraint(equalToConstant: textSize).isActive = true
            
            self.scrollView.addSubview(backButton)
            backButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: textSize + 100).isActive = true
            backButton.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
            backButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            backButton.widthAnchor.constraint(equalToConstant: self.scrollView.frame.width - 32).isActive = true
            backButton.addTarget(self, action: #selector(EULAViewController.backPressed(_:)), for: .touchUpInside)
            
        }
        self.scrollView.addSubview(topBackButton)
        topBackButton.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        topBackButton.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor).isActive = true
        topBackButton.widthAnchor.constraint(equalToConstant: 90).isActive = true
        topBackButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        topBackButton.addTarget(self, action: #selector(EULAViewController.backPressed(_:)), for: .touchUpInside)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupSubviews()

        
        print ("initial view loaded")


    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // add keyboard obersvers
         // code to force a sign out
        /* let firebaseAuth = Auth.auth()
         do {
         try firebaseAuth.signOut()
         // remove userID from keychain
         print ("user has been signed out.")
         // segue back to login screen
         
         } catch let signOutError as NSError {
         // error signing out
         print ("Error signing out: %@", signOutError)
         AlertController.showAlert(self, title: "Error", message: "Sign out request could not be completed.")
         return
         }*/
        
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    
}
