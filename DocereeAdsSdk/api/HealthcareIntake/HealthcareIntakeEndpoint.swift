import Foundation

enum HealthcareIntakeEndpoint {
    private static let intakePath = "/v1/intake"

    static func url(for environment: EnvironmentType = DocereeMobileAds.shared().getEnvironment()) -> URL? {
        let host = getHealthcareIntakeHost(type: environment)
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = intakePath
        return components.url
    }
}
