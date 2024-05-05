//
//  ContentView.swift
//  WorkoutExporter
//
//  Created by zono on 2024/05/04.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    let periods1 = ["Past Two Weeks", "This Year"]
    let periods2 = ["Last and This Year", "All Time"]
    @State private var selectedPeriod = "Past Two Weeks"
    
    var body: some View {
        VStack {
            Image(systemName: "figure.run.circle.fill")
                .foregroundColor(.green)
                .imageScale(.large)
                .dynamicTypeSize(.xxxLarge)
                .foregroundStyle(.tint)
            Text("Born to Run")
                .padding(.bottom)
            
            HStack {
                ForEach(periods1, id: \.self) {period in
                    PeriodButton(period: period, selectedPeriod: $selectedPeriod)
                }
            }

            HStack {
                ForEach(periods2, id: \.self) {period in
                    PeriodButton(period: period, selectedPeriod: $selectedPeriod)
                }
            }
            .padding(.bottom)
            
            Button("Export Workouts") {
//                workoutManager.exportAndShareWorkout()
                workoutManager.exportAndShareWorkout(for: selectedPeriod)
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
//        .onAppear { // Debug
//            workoutManager.exportAndShareWorkout()
//        }
    }
}

struct PeriodButton: View {
    let period: String
    @Binding var selectedPeriod: String
    
    var body: some View {
        Button(action: {
                selectedPeriod = period
            }) {
                Text(period)
                    .dynamicTypeSize(.xSmall)
                    .padding(.vertical, 2)
                    .padding(.horizontal)
                    .foregroundColor(selectedPeriod == period ? .primary : .primary)
                    .background(selectedPeriod == period ? Color.green: Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 2)
                    )
                    .cornerRadius(10)
            }
    }
}

#Preview {
    ContentView()
}

