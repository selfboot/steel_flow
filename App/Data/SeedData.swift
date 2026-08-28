import Foundation
import SwiftData

@MainActor
enum SeedData {
    static func ensure(in context: ModelContext) {
        let descriptor = FetchDescriptor<MaterialEntity>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let ids = Set(existing.map(\.id))
        for preset in MaterialCatalog.presets where !ids.contains(preset.id) {
            context.insert(MaterialEntity(
                id: preset.id,
                name: preset.nameKey,
                nameKey: preset.nameKey,
                densityKgPerM3: preset.densityKgPerM3,
                note: preset.noteKey,
                isBuiltIn: true
            ))
        }

        if ((try? context.fetch(FetchDescriptor<CompanyProfileEntity>())) ?? []).isEmpty {
            context.insert(CompanyProfileEntity())
        }
        if ((try? context.fetch(FetchDescriptor<AppPreferenceEntity>())) ?? []).isEmpty {
            context.insert(AppPreferenceEntity())
        }
        try? context.save()
    }
}
