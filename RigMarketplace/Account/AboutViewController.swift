//
//  AboutViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 01/06/2023.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let aboutText = """
        Welcome to the Rig Marketplace
        
        The Rig Marketplace is a mobile application that serves as a platform for users interested in building custom-built computers, commonly known as "rigs". In today's fast-paced world of computer technology, it's essential to have a reliable and convenient marketplace for buying and selling computer parts.
        
        Custom-built computers have become increasingly popular, with many companies specializing in their sales. However, due to the rapid growth of computer parts, such as the evolution of graphic cards over the years, there is a tendency to replace parts with newer versions. That's where The Rig Marketplace comes in!

        One of the key features of this application is that it provides users with a centralized marketplace to buy and sell computer parts. Whether you're looking to upgrade your rig or want to find cheaper second-hand computer parts, our marketplace has got you covered. Say goodbye to the hassle of searching through various websites and forums – we bring everything together in one convenient place.

        But The Rig Marketplace is more than just a marketplace. We believe in empowering our users with the tools and knowledge to build their dream rigs. That's why we've included a virtual assistant that will guide and assist you throughout the entire process. From selecting the right components to ensuring compatibility, our virtual assistant has got your back.

        Additionally, we understand the importance of community and sharing ideas. That's why we've created a community forum where users can connect, share their rigs, and discuss their experiences. Not only can you showcase your rig, but you can also provide a full component-price breakdown, helping others make informed decisions.

        The Rig Marketplace is designed with gamers and students in mind, as these audiences are often passionate about custom-built computers. We believe that everyone should have access to high-quality and affordable computer parts, and our app is here to make that a reality.

        We would like to acknowledge the following licenses and references that have contributed to the development of The Rig Marketplace:

        1. Firebase: The Rig Marketplace utilizes Firebase for its backend infrastructure and authentication system, ensuring a secure and reliable user experience.
        
         Copyright 2023 Ng Jin Shan

           Licensed under the Apache License, Version 2.0 (the "License");
           you may not use this file except in compliance with the License.
           You may obtain a copy of the License at

               http://www.apache.org/licenses/LICENSE-2.0

           Unless required by applicable law or agreed to in writing, software
           distributed under the License is distributed on an "AS IS" BASIS,
           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
           See the License for the specific language governing permissions and
           limitations under the License.

        2. MessageKit: Our in-app chatbot system is powered by MessageKit.
        
        MIT License

        Copyright (c) 2017-2022 MessageKit

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        
        https://github.com/MessageKit/MessageKit
        
        3. ChatGPT53: Our chatbot system is powered by ChatGPT53's API from Rapid API.
        
        https://rapidapi.com/Glavier/api/chatgpt53
        
        
        I acknowledge the user of ChatGPT (https://chat.openai.com/) to generate materials for background research and self-study in the development of this assessment. I enter the following prompts:
        1. Write a function to find parent view controller in a UIView
        
        The output was used in my SignInViewController to performSegue from the right viewcontroller.

        Thank you for choosing The Rig Marketplace. We are excited to have you join our community and help you build the rig of your dreams!

        """
        
        textView.text = aboutText
        textView.isEditable = false
        textView.isScrollEnabled = true
    }
}
