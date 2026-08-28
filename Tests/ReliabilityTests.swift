import XCTest
import SwiftData
@testable import SteelFlow

@MainActor
final class ReliabilityTests: XCTestCase {
    private final class FailureSwitch {
        var isEnabled = true
    }

    private enum TestFailure: LocalizedError {
        case expected
        var errorDescription: String? { "Expected test failure" }
    }

    func testRevokedOrMissingCurrentEntitlementClearsCachedPro() {
        XCTAssertTrue(PurchaseManager.resolvedEntitlement(hasVerifiedCurrentEntitlement: true))
        XCTAssertFalse(PurchaseManager.resolvedEntitlement(hasVerifiedCurrentEntitlement: false))
    }

    func testRevenueCatKeyValidationAllowsAppleKeysInEveryBuild() {
        XCTAssertTrue(PurchaseManager.isAcceptableAPIKey(" appl_public_key ", debugBuild: true))
        XCTAssertTrue(PurchaseManager.isAcceptableAPIKey("appl_public_key", debugBuild: false))
    }

    func testRevenueCatKeyValidationNeverShipsTestStoreKey() {
        XCTAssertTrue(PurchaseManager.isAcceptableAPIKey("test_public_key", debugBuild: true))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("test_public_key", debugBuild: false))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("REVENUECAT_API_KEY_NOT_CONFIGURED", debugBuild: true))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("", debugBuild: false))
    }

    func testPersistenceErrorCenterReportsFailureAndClearsAfterSuccess() {
        let center = PersistenceErrorCenter()
        XCTAssertFalse(center.perform { throw TestFailure.expected })
        XCTAssertEqual(center.message, "Expected test failure")
        XCTAssertTrue(center.perform {})
        XCTAssertNil(center.message)
    }

    func testDataStoreFailureShowsRecoverableStateAndRetrySeedsDatabase() throws {
        let failureSwitch = FailureSwitch()
        let store = AppDataStore {
            if failureSwitch.isEnabled { throw TestFailure.expected }
            return try Self.inMemoryContainer()
        }

        XCTAssertNil(store.container)
        XCTAssertEqual(store.errorDescription, "Expected test failure")

        failureSwitch.isEnabled = false
        store.retry()

        let container = try XCTUnwrap(store.container)
        XCTAssertTrue(store.errorDescription.isEmpty)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<MaterialEntity>()).count, MaterialCatalog.presets.count)
    }

    private static func inMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            MaterialEntity.self, PriceBookEntryEntity.self, ProjectEntity.self, CalculationItemEntity.self,
            CustomerEntity.self, CompanyProfileEntity.self, QuoteSnapshotEntity.self, AppPreferenceEntity.self
        ])
        return try ModelContainer(for: schema, configurations: [.init(schema: schema, isStoredInMemoryOnly: true)])
    }
}
