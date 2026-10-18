import XCTest
import SwiftData
import RevenueCat
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

    func testProductLoadingRecoversAfterFailureWithoutChangingEntitlement() async {
        let manager = PurchaseManager(startListening: false)
        let previousEntitlement = manager.isPro
        await manager.loadProduct { throw TestFailure.expected }
        XCTAssertNotNil(manager.availabilityMessage)
        XCTAssertFalse(manager.isLoading)

        await manager.loadProduct { Self.lifetimePackage() }
        XCTAssertEqual(manager.localizedPrice, "$14.99")
        XCTAssertNil(manager.availabilityMessage)
        XCTAssertEqual(manager.isPro, previousEntitlement)
        XCTAssertFalse(manager.isLoading)

        // A later catalog refresh failure must not throw away an already usable product.
        await manager.loadProduct { throw TestFailure.expected }
        XCTAssertEqual(manager.localizedPrice, "$14.99")
        XCTAssertNil(manager.availabilityMessage)
    }

    func testCancelledProductLoadKeepsPriceAndDoesNotShowStoreError() async {
        let manager = PurchaseManager(startListening: false)
        await manager.loadProduct { Self.lifetimePackage() }
        await manager.loadProduct { throw CancellationError() }
        XCTAssertEqual(manager.localizedPrice, "$14.99")
        XCTAssertNil(manager.availabilityMessage)
        XCTAssertFalse(manager.isLoading)
    }

    func testOverlappingProductLoadsCannotOverwriteTheActiveRequest() async {
        let manager = PurchaseManager(startListening: false)
        await manager.loadProduct {
            XCTAssertTrue(manager.isLoadingProducts)
            await manager.loadProduct {
                XCTFail("The second caller must reuse the active load")
                return nil
            }
            return Self.lifetimePackage()
        }
        XCTAssertEqual(manager.localizedPrice, "$14.99")
        XCTAssertFalse(manager.isLoading)
        await manager.loadProduct { nil }
        XCTAssertNil(manager.localizedPrice)
        XCTAssertNotNil(manager.availabilityMessage)
    }

    private static func lifetimePackage() -> Package {
        let product = TestStoreProduct(
            localizedTitle: "SteelFlow Pro", price: 14.99, currencyCode: "USD",
            localizedPriceString: "$14.99", productIdentifier: PurchaseManager.productID,
            productType: .nonConsumable, localizedDescription: "Lifetime unlock",
            locale: Locale(identifier: "en_US")
        )
        return Package(identifier: "$rc_lifetime", packageType: .lifetime,
                       storeProduct: product.toStoreProduct(), offeringIdentifier: "default",
                       webCheckoutUrl: nil)
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
