//
//  DiscordComponents.swift
//  Swift-Webserver
//
//  Created by GreenyCells (Mineturtlee) on 8/11/25.
//

import Foundation

protocol Components: Encodable {
    var type: ComponentsTypes { get }
    // let id: Int32
    var custom_id: String? { get }
}

struct Button: Components {
    let type = ComponentsTypes.Button
    let style: ButtonStyle
    let label: String
    var custom_id: String?
    let disabled: Bool?

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(style, forKey: .style)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(custom_id, forKey: .custom_id)
        try container.encodeIfPresent(disabled, forKey: .disabled)
    }

    private enum CodingKeys: String, CodingKey {
        case type, style, label, custom_id, disabled
    }
}

struct TextDisplay: Components {
    let type = ComponentsTypes.TextDisplay
    let content: String
    let custom_id: String? = nil
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(content, forKey: .content)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, content
    }
}

struct Separator: Components {
    let type = ComponentsTypes.Separator
    let custom_id: String? = nil
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
}

struct Container: Components {
    let type = ComponentsTypes.Container
    let accent_color: Int?
    let components: [AnyEncodable]
    var custom_id: String? = nil
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(accent_color, forKey: .accent_color)

        var nested = container.nestedUnkeyedContainer(forKey: .components)
        for comp in components {
            try comp.encode(to: nested.superEncoder())
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, accent_color, components
    }
}

struct ActionRow: Components {
    let custom_id: String? = nil
    let type = ComponentsTypes.ActionRow
    let components: [any Components]

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        var nested = container.nestedUnkeyedContainer(forKey: .components)
        for comp in components {
            try comp.encode(to: nested.superEncoder())
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, components
    }
}


enum ButtonStyle: Int, Encodable {
    case primary = 1
    case secondary = 2
    case success = 3
    case danger = 4
    case link = 5
}

enum ComponentsTypes: Int, Encodable {
    case ActionRow = 1
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
    // case Label = 18
    // let FileUpload = 19
}

struct AnyEncodable: Encodable {
    private let _encode: (any Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: any Encoder) throws {
        try _encode(encoder)
    }
}


struct WebhookBody: Encodable {
    let components: [any Components]
    let flags: Int = 1 << 15

    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(flags, forKey: .flags)

        var nested = container.nestedUnkeyedContainer(forKey: .components)
        for component in components {
            try component.encode(to: nested.superEncoder())
        }
    }

    private enum CodingKeys: String, CodingKey {
        case flags
        case components
    }
}
