//
//  DiscordComponents.swift
//  Swift-Webserver
//
//  Created by GreenyCells (Mineturtlee) on 8/11/25.
//

import Foundation

struct Components: Encodable {
    let type: ComponentsTypes
    let id: Int32
    let custom_id: String = ""
}

struct Button: Encodable {
    let type = 2
    // let id: Int
    let style: ButtonStyle
}

struct TextDisplay: Encodable {
    
}

enum ButtonStyle: Int, Encodable {
    case primary = 1
    case secondary = 2
    case success = 3
    case danger = 4
    case link = 5
}

enum ComponentsTypes: Int, Encodable {
    // let ActionRow = 1
    case Button = 2
    // let StringSelect = 3
    // let TextInput = 4
    // let UserSelect = 5
    // let RoleSelect = 6
    // let MentionableSelect = 7
    // let ChannelSelect = 8
    // case Section = 9
    case TextDisplay = 10
    // let Thumbnail = 11
    // let MediaGallery = 12
    // let File = 13
    case Separator = 14
    case Container = 17
    case Label = 18
    // let FileUpload = 19
}

/*
 struct body: Encodable {
    let Components: Array
 }
 */
