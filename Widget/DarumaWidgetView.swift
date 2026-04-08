import SwiftUI
import WidgetKit

struct DarumaWidgetView: View {
    let entry: DarumaEntry
    @Environment(\.widgetFamily) var family

    var imageName: String {
        let prefix = entry.eyeState == .oneEye ? "oneeye" : "fulleye"

        switch family {
        case .systemSmall:
            let num = entry.style == .style2 ? 2 : 1
            return "\(prefix)_small_\(num)"
        case .systemMedium:
            let num: Int
            switch entry.style {
            case .style1: num = 1
            case .style2: num = 2
            case .style3: num = 3
            }
            return "\(prefix)_medium_\(num)"
        case .systemLarge:
            let num = entry.style == .style2 ? 2 : 1
            return "\(prefix)_big_\(num)"
        default:
            return "\(prefix)_small_1"
        }
    }

    var imageScale: CGFloat {
        switch family {
        case .systemSmall:  return 1.0
        case .systemMedium: return 1.0
        case .systemLarge:  return 1.0
        default:            return 1.0
        }
    }

    var body: some View {
        Color.clear
            .containerBackground(for: .widget) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(imageScale)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
            }
    }
}
