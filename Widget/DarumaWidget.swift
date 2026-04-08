import WidgetKit
import SwiftUI

struct DarumaWidget: Widget {
    let kind: String = "DarumaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DarumaWidgetIntent.self,
            provider: DarumaProvider()
        ) { entry in
            DarumaWidgetView(entry: entry)
        }
        .configurationDisplayName("Daruma")
        .description("Your Daruma keychain on the Home Screen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct DarumaWidgetBundle: WidgetBundle {
    var body: some Widget {
        DarumaWidget()
    }
}
