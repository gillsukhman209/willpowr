//
//  willpowrwidgetLiveActivity.swift
//  willpowrwidget
//
//  Created by Sukhman Singh on 8/15/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct willpowrwidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct willpowrwidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: willpowrwidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension willpowrwidgetAttributes {
    fileprivate static var preview: willpowrwidgetAttributes {
        willpowrwidgetAttributes(name: "World")
    }
}

extension willpowrwidgetAttributes.ContentState {
    fileprivate static var smiley: willpowrwidgetAttributes.ContentState {
        willpowrwidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: willpowrwidgetAttributes.ContentState {
         willpowrwidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: willpowrwidgetAttributes.preview) {
   willpowrwidgetLiveActivity()
} contentStates: {
    willpowrwidgetAttributes.ContentState.smiley
    willpowrwidgetAttributes.ContentState.starEyes
}
