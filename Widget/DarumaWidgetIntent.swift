import AppIntents
import WidgetKit

enum WidgetStyle: String, CaseIterable, AppEnum {
    case style1
    case style2
    case style3

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static var caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] = [
        .style1: "Style 1",
        .style2: "Style 2",
        .style3: "Style 3"
    ]
}

enum EyeState: String, CaseIterable, AppEnum {
    case oneEye
    case fullEye

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Eyes"
    static var caseDisplayRepresentations: [EyeState: DisplayRepresentation] = [
        .oneEye: "One Eye",
        .fullEye: "Both Eyes"
    ]
}

struct DarumaWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Customize Widget"
    static var description = IntentDescription("Choose the style of your Daruma")

    @Parameter(title: "Style", default: .style1)
    var style: WidgetStyle

    @Parameter(title: "Eyes", default: .oneEye)
    var eyeState: EyeState
}
