import SwiftUI
import Foundation

struct Message {
    static var text = "..."
}

struct ContentView: View {
    var body: some View {
        Text(Message.text)
            .padding()
    }
}

@main
struct smstApp: App {
    let smsMonitor = SMSMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    smsMonitor.startMonitoring()
                }
                .onDisappear {
                    smsMonitor.stopMonitoring()
                }
        }
    }
}
