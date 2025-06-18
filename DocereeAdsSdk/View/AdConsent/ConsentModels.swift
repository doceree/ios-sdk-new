//
//  ConsentModels.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 17/06/25.
//

import Foundation

import Foundation

/// Enum representing different reasons a user might block or report an ad.
enum BlockLevel: CaseIterable {
    case AdCoveringContent
    case AdWasInappropriate
    case NotInterestedInCampaign
    case NotInterestedInBrand
    case NotInterestedInBrandType
    case NotInterestedInClientType

    /// Returns the block level code and a user-friendly description.
    var info: (blockLevelCode: String, blockLevelDesc: String) {
        switch self {
        case .AdCoveringContent:
            return ("overlappingAd", "Ad is covering the content of the website.")
        case .AdWasInappropriate:
            return ("inappropriateAd", "Ad was inappropriate.")
        case .NotInterestedInCampaign:
            return ("notInterestedInCampaign", "I'm not interested in seeing ads for this product")
        case .NotInterestedInBrand:
            return ("notInterestedInBrand", "I'm not interested in seeing ads for this brand.")
        case .NotInterestedInBrandType:
            return ("notInterestedInBrandType", "I'm not interested in seeing ads for this category.")
        case .NotInterestedInClientType:
            return ("notInterestedInClientType", "I'm not interested in seeing ads from pharmaceutical brands.")
        }
    }
}
