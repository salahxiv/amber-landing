import WidgetKit
import SwiftUI

@main
struct EyeRestWidgetBundle: WidgetBundle {
    var body: some Widget {
        EyeRestLiveActivity()
        EyeRestTimerWidget()
    }
}
