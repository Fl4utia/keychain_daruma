import WidgetKit
import Foundation

struct DarumaEntry: TimelineEntry {
    let date: Date
    let style: WidgetStyle
    let eyeState: EyeState
}

struct DarumaProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> DarumaEntry {
        DarumaEntry(date: Date(), style: .style1, eyeState: .oneEye)
    }

    func snapshot(for configuration: DarumaWidgetIntent, in context: Context) async -> DarumaEntry {
        DarumaEntry(date: Date(), style: configuration.style, eyeState: configuration.eyeState)
    }

    func timeline(for configuration: DarumaWidgetIntent, in context: Context) async -> Timeline<DarumaEntry> {
        let entry = DarumaEntry(date: Date(), style: configuration.style, eyeState: configuration.eyeState)
        return Timeline(entries: [entry], policy: .never)
    }
}
