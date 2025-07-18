//
//  ContentView.swift
//  WillPowr
//
//  Created by Sukhman Singh on 7/18/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
            .environmentObject(DataService.shared)
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
            
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
