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
        XCTAssertTrue(PurchaseManager.isAcceptableAPIKey(" appl_1234567890AbCdEf ", debugBuild: true))
        XCTAssertTrue(PurchaseManager.isAcceptableAPIKey("appl_1234567890AbCdEf", debugBuild: false))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("appl_short", debugBuild: false))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("appl_1234567890_bad_key", debugBuild: false))
    }

    func testRevenueCatKeyValidationNeverShipsTestStoreKey() {
        XCTAssertTrue(PurchaseManager.isAcceptableAPIKey("test_1234567890AbCdEf", debugBuild: true))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("test_1234567890AbCdEf", debugBuild: false))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("REVENUECAT_API_KEY_NOT_CONFIGURED", debugBuild: true))
        XCTAssertFalse(PurchaseManager.isAcceptableAPIKey("", debugBuild: false))
    }

    func testFreeProjectLimitAlsoAppliesWhenRestoringArchivedProjects() {
        XCTAssertTrue(ProPolicy.canActivateProject(activeProjectCount: 1, isPro: false))
        XCTAssertFalse(ProPolicy.canActivateProject(activeProjectCount: 2, isPro: false))
        XCTAssertTrue(ProPolicy.canActivateProject(activeProjectCount: 2, isPro: true))
    }

    func testDeletingProjectPermanentlyCascadesToItsItems() throws {
        let container = try Self.inMemoryContainer()
        let context = container.mainContext
        let project = ProjectEntity(name: "Delete me")
        project.items = [CalculationItemEntity(
            profile: .plate,
            geometry: GeometryInput(values: [.width: 100, .thickness: 10]),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 1,
            wastePercent: 0,
            priceBasis: .perKilogram,
            unitPrice: 1
        )]
        context.insert(project)
        try context.save()

        context.delete(project)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectEntity>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<CalculationItemEntity>()).count, 0)
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
