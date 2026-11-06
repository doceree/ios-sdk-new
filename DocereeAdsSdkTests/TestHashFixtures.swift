import Foundation

/// Lowercase SHA-256 hex (64 chars), no `sha256:` prefix — matches publisher / Platform Guide format.
enum TestHashFixtures {
    static let hashedHcpId = "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"
    static let hashedEmail = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
    static let hashedMobile = "c84d9f2e7f92b952ba89a147e910f579f352e198789a8b0d0c3d773b6b4cb2a"
    static let hashedAssociateId = "d44f1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef123456"
    static let hashedPatientId = "5566778899aabbccddeeff00112233445566778899aabbccddeeff0011223344"
    static let hashedEmailAlt = "aa11aabbccdd1122aa11aabbccdd1122aa11aabbccdd1122aa11aabbccdd1122"
    static let hashedMobileAlt = "bb22aabbccdd1122bb22aabbccdd1122bb22aabbccdd1122bb22aabbccdd1122"
    static let hashedSsn = "cc33aabbccdd1122cc33aabbccdd1122cc33aabbccdd1122cc33aabbccdd1122"
    static let hashedHcpIdClinical = "38d8c2b7e3d9f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7"
    static let hashedUserProfileId = "111122223333444455556666777788889999aaaabbbbccccddddeeeeffff0000"
}
