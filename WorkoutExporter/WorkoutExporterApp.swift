//
//  WorkoutExporterApp.swift
//  WorkoutExporter
//
//  Created by zono on 2024/05/04.
//

import SwiftUI
import HealthKit

@main
struct WorkoutExporterApp: App {
    let healthStore = HKHealthStore()

    init() {
        authorizeHealthKit()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WorkoutManager(healthStore: self.healthStore))
        }
    }
    
    func authorizeHealthKit() {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
              let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        let healthKitTypeToRead: Set<HKObjectType> = [
            distanceType,
            caloriesType,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypeToRead) { success, error in
            if !success {
                // Error handling
                print("HealthKit Authorization Failed: \(String(describing: error))")
            }
        }
    }
}

class WorkoutManager: ObservableObject {
    var healthStore: HKHealthStore
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    func fetchSwimmingWorkouts(){
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
            (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                // error handling
                print("Failed to fetch workouts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for workout in workouts.prefix(3) {
                print("Workout: \(workout), calories: \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) kcal, distance: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0) m")
            }
        }
        
        self.healthStore.execute(query)
    }
}
