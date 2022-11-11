
import Foundation

// MARK: Archiving paths
let DocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let PlatformArchivingUrl = DocumentsDirectory.appendingPathComponent("platformUId")
let ProfileArchivingUrl = DocumentsDirectory.appendingPathComponent("hcpProfile")
let DocereeAdsIdArchivingUrl = DocumentsDirectory.appendingPathComponent("DocereeAdsId")
let EventListArchivingUrl = DocumentsDirectory.appendingPathComponent("EventList")
let EditorialTagsArchivingUrl = DocumentsDirectory.appendingPathComponent("EditorialTags")
let RxDxCodesArchivingUrl = DocumentsDirectory.appendingPathComponent("RxDxCodes")
