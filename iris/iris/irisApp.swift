//
//  irisApp.swift
//  iris
//
//  Created by ssb on 5/11/26.
//

import SwiftUI
import CoreData

@main
struct irisApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
