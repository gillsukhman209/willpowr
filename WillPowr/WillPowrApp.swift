//
//  WillPowrApp.swift
//  WillPowr
//
//  Created by Sukhman Singh on 7/18/25.
//

import SwiftUI

@main
struct WillPowrApp: App {
    // MARK: - Properties
    let dataService = DataService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .environment(\.managedObjectContext, dataService.context)
        }
    }
}
