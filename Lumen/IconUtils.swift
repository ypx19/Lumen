//
//  IconUtils.swift
//  AdvxProject1
//
//  Created by AI Assistant.
//

import Foundation

func getSystemIcon(for imageName: String) -> String {
    switch imageName {
    case "living_room":
        return "sofa"
    case "kitchen":
        return "fork.knife"
    case "house_overview":
        return "house"
    case "coding_time":
        return "laptopcomputer"
    case "breakfast":
        return "cup.and.saucer"
    default:
        return "photo"
    }
}