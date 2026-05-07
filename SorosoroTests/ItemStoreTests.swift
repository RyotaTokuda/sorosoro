import XCTest
@testable import Sorosoro

final class ItemTests: XCTestCase {
    func testItemStatusOverdue() {
        let item = Item(
            name: "テスト",
            mode: .daily,
            cycleDays: 30,
            lastPurchaseDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        )
        XCTAssertEqual(item.status, .overdue)
        XCTAssertTrue(item.daysRemaining < 0)
    }

    func testItemStatusSoon() {
        let item = Item(
            name: "テスト",
            mode: .daily,
            cycleDays: 30,
            lastPurchaseDate: Calendar.current.date(byAdding: .day, value: -28, to: Date())!,
            notificationDaysBefore: 3
        )
        XCTAssertEqual(item.status, .soon)
    }

    func testItemStatusOk() {
        let item = Item(
            name: "テスト",
            mode: .daily,
            cycleDays: 30,
            lastPurchaseDate: Date()
        )
        XCTAssertEqual(item.status, .ok)
        XCTAssertEqual(item.daysRemaining, 30)
    }

    func testMarkPurchased() {
        var item = Item(
            name: "テスト",
            mode: .daily,
            cycleDays: 30,
            lastPurchaseDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        )
        XCTAssertEqual(item.status, .overdue)

        item.markPurchased()
        XCTAssertEqual(item.status, .ok)
        XCTAssertEqual(item.daysRemaining, 30)
    }

    func testDefaultTemplatesExist() {
        XCTAssertFalse(DefaultTemplates.daily.isEmpty)
        XCTAssertFalse(DefaultTemplates.car.isEmpty)
        XCTAssertFalse(DefaultTemplates.gadget.isEmpty)

        for template in DefaultTemplates.all {
            XCTAssertTrue(template.isDefault)
            XCTAssertTrue(template.cycleDays > 0)
        }
    }

    func testPlanLimitsFree() {
        XCTAssertEqual(PlanLimits.itemLimit(isPro: false), 10)
        XCTAssertEqual(PlanLimits.notificationLimit(isPro: false), 5)
        XCTAssertFalse(PlanLimits.canCreateCustomTemplate(isPro: false))
        XCTAssertFalse(PlanLimits.canUseAllModes(isPro: false))
    }

    func testPlanLimitsPro() {
        XCTAssertEqual(PlanLimits.itemLimit(isPro: true), .max)
        XCTAssertEqual(PlanLimits.notificationLimit(isPro: true), 64)
        XCTAssertTrue(PlanLimits.canCreateCustomTemplate(isPro: true))
        XCTAssertTrue(PlanLimits.canUseAllModes(isPro: true))
    }
}

extension ItemStatus: Equatable {}
