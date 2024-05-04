//
//  WorkoutExporterApp.swift
//  WorkoutExporter
//
//  Created by zono on 2024/05/04.
//

import SwiftUI
import HealthKit
import Zip

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

    func fetchSwimmingWorkouts(completion: @escaping (String) -> Void){
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
            (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                // error handling
                print("Failed to fetch workouts: \(error?.localizedDescription ?? "Unknown error")")
                completion("")
                return
            }
            
            for workout in workouts.prefix(3) {
                print("Workout: \(workout), WorkoutEvents: \(String(describing: workout.workoutEvents)),　calories: \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) kcal, distance: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0) m")
            }
            
            let jsonData = self.convertToJsonData(workouts)
            completion(jsonData)
        }
        
        self.healthStore.execute(query)
    }
    
    private func convertToJsonData(_ workouts: [HKWorkout]) -> String {
        var jsonArray = [Any]()
        
        for workout in workouts.prefix(3) {
            var workoutData = [String: Any]()
            //workoutData["startTime"] = workout.startDate
            workoutData["duration"] = workout.duration
            workoutData["caloriesBurned"] = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            workoutData["distance"] = workout.totalDistance?.doubleValue(for: .meter())
            
            jsonArray.append(workoutData)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonArray, options:[JSONSerialization.WritingOptions.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Failed to convert to JSON")
            return ""
        }
    }
    
    func exportAndShareWorkout() {
        fetchSwimmingWorkouts { jsonData in
            guard !jsonData.isEmpty else { return }
            
            let fileManager = FileManager.default
            let tempDirectory = fileManager.temporaryDirectory
            let jsonFileURL = tempDirectory.appendingPathComponent("workouts.json")
            
            do {
                try jsonData.write(to: jsonFileURL, atomically: true, encoding: .utf8)
                
                let zipFilePath = tempDirectory.appendingPathComponent("workouts.zip")
                try Zip.zipFiles(paths: [jsonFileURL], zipFilePath: zipFilePath, password: nil, progress: nil)
                print("Zip file created at \(zipFilePath)")
                DispatchQueue.main.async {
                    self.shareFile(fileURL: zipFilePath)
                }
            } catch {
                print("Failed to write JSON or zip files: \(error)")
            }
        }
    }
    
    private func shareFile(fileURL: URL) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let rootViewController = windowScene?.windows.first?.rootViewController
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        DispatchQueue.main.async {
            rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
}
