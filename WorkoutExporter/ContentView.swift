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
            Image(systemName: "figure.run.circle.fill")
                .foregroundColor(.green)
                .imageScale(.large)
                .dynamicTypeSize(.xxxLarge)
                .foregroundStyle(.tint)
            Text("Born to Run")
                .padding(.bottom)
            Button("Export Workouts") {
                workoutManager.exportAndShareWorkout()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

