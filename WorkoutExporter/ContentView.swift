//
//  ContentView.swift
//  WorkoutExporter
//
//  Created by zono on 2024/05/04.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            workoutManager.fetchSwimmingWorkouts()
        }
    }
}

#Preview {
    ContentView()
}

