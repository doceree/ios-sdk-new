import XCTest
@testable import DocereeAdsSdk

final class DataAttributesPayloadBuilderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "patientData")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "patientData")
        super.tearDown()
    }

    func testAddPersistsPatientDetailsToStorage() {
        let patientDetails: [String: Any] = [
            "patientId": "PT-00112",
            "name": "Jane Doe"
        ]

        _ = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.patientDetailsKey, value: patientDetails)

        let stored = StorageManager.shared.getPatientData()
        let nested = stored?[DataAttributesPayloadBuilder.patientDetailsKey] as? [String: Any]
        XCTAssertEqual(nested?["patientId"] as? String, "PT-00112")
    }

    func testAddKeepsDistinctActionEventTypesAcrossBuilders() {
        let firstEvent: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]
        let secondEvent: [String: Any] = [
            "type": "checkout",
            "timestamp": "2026-01-01T11:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]

        _ = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: firstEvent)
        _ = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: secondEvent)

        let events = StorageManager.shared.getPatientData()?[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]]
        XCTAssertEqual(events?.count, 2)
        XCTAssertEqual(events?.first?["type"] as? String, "appt_request")
        XCTAssertEqual(events?.last?["type"] as? String, "checkout")
    }

    func testAddReplacesExistingActionEventWithSameType() {
        let firstEvent: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]
        let updatedEvent: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T12:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-2"
        ]

        _ = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: firstEvent)
        _ = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: updatedEvent)

        let events = StorageManager.shared.getPatientData()?[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["type"] as? String, "appt_request")
        XCTAssertEqual(events?.first?["appointmentId"] as? String, "appt-2")
        XCTAssertEqual(events?.first?["timestamp"] as? String, "2026-01-01T12:00:00Z")
    }

    func testAddReplacesSameTypeWithinSingleBuilder() {
        let firstEvent: [String: Any] = [
            "type": "checkout",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]
        let updatedEvent: [String: Any] = [
            "type": "checkout",
            "timestamp": "2026-01-01T11:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]

        let json = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: firstEvent)
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: updatedEvent)
            .build()
            .toJson()

        let events = json[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["timestamp"] as? String, "2026-01-01T11:00:00Z")
    }

    func testSavePatientDataRemovesDuplicateActionTypesFromLegacyStorage() {
        let legacyPayload: [String: Any] = [
            DataAttributesPayloadBuilder.actionEventKey: [
                [
                    "type": "appt_request",
                    "timestamp": "2026-01-01T10:00:00Z",
                    "patientId": "pat-1",
                    "appointmentId": "appt-1"
                ],
                [
                    "type": "appt_request",
                    "timestamp": "2026-01-01T11:00:00Z",
                    "patientId": "pat-1",
                    "appointmentId": "appt-2"
                ]
            ]
        ]

        StorageManager.shared.savePatientData(legacyPayload)

        let atdBeforeSave = decodeBase64JSONArray(PatientSession().getAtd())
        XCTAssertEqual(atdBeforeSave?.count, 1)
        XCTAssertEqual(atdBeforeSave?.first?["appointmentId"] as? String, "appt-2")

        _ = PatientSession().savePatientData([:])

        let events = StorageManager.shared.getPatientData()?[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["appointmentId"] as? String, "appt-2")
        XCTAssertEqual(events?.first?["type"] as? String, "appt_request")
    }

    func testDataAttributesPayloadToJsonOmitsEmptyDefaultBuilder() {
        let json = DataAttributesPayloadBuilder().build().toJson()
        XCTAssertTrue(json.isEmpty, "All-default payload fields should be filtered out")
    }

    func testDataAttributesPayloadToJsonIncludesAgeUnderPatientDataKey() {
        let json = DataAttributesPayloadBuilder().add(key: "age", value: "42").build().toJson()
        XCTAssertEqual(json["ag"] as? String, "42")
    }

    func testDataAttributesPayloadToJsonIncludesSessionIdUnderPatientDataKey() {
        let json = DataAttributesPayloadBuilder().add(key: "sessionId", value: "sess-1").build().toJson()
        XCTAssertEqual(json["sid"] as? String, "sess-1")
    }

    func testSessionDetailsPreservesCanonicalSessionKeys() {
        let payload: [[String: Any]] = [
            ["dxCode": "E11.9", "status": "active"]
        ]
        let sessionDetails: [String: Any] = ["diagnosis_v1": payload]
        let json = DataAttributesPayloadBuilder().add(key: DataAttributesPayloadBuilder.sessionDetailsKey, value: sessionDetails).build().toJson()
        let nested = json[DataAttributesPayloadBuilder.sessionDetailsKey] as? [String: Any]
        let mapped = nested?["diagnosis_v1"] as? [[String: Any]]
        XCTAssertEqual(mapped?.count, 1)
        XCTAssertEqual(mapped?.first?["dxCode"] as? String, "E11.9")
    }

    func testSessionDetailsDeepMergesAcrossAdds() {
        let json = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.sessionDetailsKey, value: ["diagnosis_v1": [["dxCode": "E11.9", "status": "active"]]])
            .add(key: DataAttributesPayloadBuilder.sessionDetailsKey, value: ["heartRate": 72])
            .build()
            .toJson()
        let nested = json[DataAttributesPayloadBuilder.sessionDetailsKey] as? [String: Any]
        XCTAssertEqual((nested?["heartRate"] as? Int), 72)
        let dx = nested?["diagnosis_v1"] as? [[String: Any]]
        XCTAssertEqual(dx?.first?["dxCode"] as? String, "E11.9")
    }

    func testActionEventValidationRejectsMissingAppointmentCommonFields() {
        let invalidAction: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1"
        ]

        let json = DataAttributesPayloadBuilder().add(key: DataAttributesPayloadBuilder.actionEventKey, value: invalidAction).build().toJson()
        XCTAssertNil(json[DataAttributesPayloadBuilder.actionEventKey], "Invalid appointment action should be dropped")
    }

    func testActionEventValidationAcceptsRequiredAppointmentCommonFields() {
        let validAction: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]

        let json = DataAttributesPayloadBuilder().add(key: DataAttributesPayloadBuilder.actionEventKey, value: validAction).build().toJson()
        let events = json[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["appointmentId"] as? String, "appt-1")
    }

    func testUserDetailsAndHealthAssociateArePreserved() {
        let userDetails: [String: Any] = [
            "hcpId": "HCP-1001",
            "hashedHcpId": "sha256:hcp1001",
            "email": "hcp@example.com",
            "mobile": "+1-555-000-4444",
            "hashedEmail": "sha256:email",
            "hashedMobile": "sha256:mobile",
            "firstName": "John",
            "lastName": "Doe",
            "gender": "m",
            "country": "US",
            "state": "CA",
            "city": "SF",
            "zipCode": "94105",
            "dob": "1980-01-01",
            "specialization": "cardiology"
        ]
        let healthAssociate: [String: Any] = [
            "dateOfBirth": "1990-01-01",
            "gender": "f"
        ]

        let json = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.userDetailsKey, value: userDetails)
            .add(key: DataAttributesPayloadBuilder.healthAssociateKey, value: healthAssociate)
            .build()
            .toJson()

        let user = json[DataAttributesPayloadBuilder.userDetailsKey] as? [String: Any]
        let associate = json[DataAttributesPayloadBuilder.healthAssociateKey] as? [String: Any]
        XCTAssertEqual(user?["hcpId"] as? String, "HCP-1001")
        XCTAssertEqual(user?["hashedHcpId"] as? String, "sha256:hcp1001")
        XCTAssertEqual(user?["specialization"] as? String, "cardiology")
        XCTAssertEqual(associate?["gender"] as? String, "f")
    }

    func testPatientDetailsObjectIsPreserved() {
        let patientDetails: [String: Any] = [
            "patientId": "pat-11",
            "hashedId": "sha256:abc",
            "mobile": "+1-555-001"
        ]
        let json = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.patientDetailsKey, value: patientDetails)
            .build()
            .toJson()
        let details = json[DataAttributesPayloadBuilder.patientDetailsKey] as? [String: Any]
        XCTAssertEqual(details?["patientId"] as? String, "pat-11")
    }

    func testPatientSessionSplitsStoredAttributesForAdRequest() {
        let patientDetails: [String: Any] = ["patientId": "pat-11", "name": "Jane"]
        let sessionDetails: [String: Any] = ["heartRate": 72]
        let actionEvent: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-11",
            "appointmentId": "appt-1"
        ]

        _ = DataAttributesPayloadBuilder()
            .add(key: DataAttributesPayloadBuilder.patientDetailsKey, value: patientDetails)
            .add(key: DataAttributesPayloadBuilder.sessionDetailsKey, value: sessionDetails)
            .add(key: "sessionId", value: "sess-99")
            .add(key: DataAttributesPayloadBuilder.actionEventKey, value: actionEvent)

        let session = PatientSession()
        let ptd = session.getPtd()
        let atd = session.getAtd()
        let br = session.getBr()

        XCTAssertFalse(ptd.isEmpty)
        let decodedPtd = decodeBase64JSON(ptd)
        XCTAssertEqual(decodedPtd?["patientId"] as? String, "pat-11")
        let decodedAtd = decodeBase64JSONArray(atd)
        XCTAssertEqual(decodedAtd?.count, 1)
        XCTAssertEqual(decodedAtd?.first?["appointmentId"] as? String, "appt-1")
        XCTAssertFalse(br.isEmpty)

        let decodedBr = decodeBase64JSON(br)
        XCTAssertEqual(decodedBr?["heartRate"] as? Int, 72)
        XCTAssertEqual(decodedBr?["sid"] as? String, "sess-99")
        XCTAssertNil(decodedBr?["patientDetails"])
        XCTAssertNil(decodedBr?["actionEvent"])
    }

    func testAdRequestPayloadAssemblerIncludesPtdAtdAndBr() {
        let ptd = encodeBase64JSON(["patientId": "pat-1"])
        let atd = encodeBase64JSONArray([["type": "checkout", "patientId": "pat-1", "appointmentId": "appt-1", "timestamp": "2026-01-01T11:00:00Z"]])
        let user = HcpBuilder()
            .setEmail("hcp@test.com")
            .setFirstName("John")
            .setLastName("Doe")
            .build()

        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: user,
            adUnitId: "unit",
            consent: ConsentSignals(),
            universalIds: UniversalIds(),
            br: "encoded-session",
            ptd: ptd,
            atd: atd
        )

        let bodyPtd = body[QueryParamsForAdRequest.ptd.rawValue] as? String
        let bodyAtd = body[QueryParamsForAdRequest.atd.rawValue] as? String
        XCTAssertEqual(decodeBase64JSON(bodyPtd ?? "")?["patientId"] as? String, "pat-1")
        XCTAssertEqual(decodeBase64JSONArray(bodyAtd ?? "")?.count, 1)
        XCTAssertEqual(body[QueryParamsForAdRequest.br.rawValue] as? String, "encoded-session")
    }

    private func decodeBase64JSON(_ encoded: String) -> [String: Any]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    private func decodeBase64JSONArray(_ encoded: String) -> [[String: Any]]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return json
    }

    private func encodeBase64JSONArray(_ object: [[String: Any]]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return data.base64EncodedString()
    }

    private func encodeBase64JSON(_ object: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return data.base64EncodedString()
    }
}
