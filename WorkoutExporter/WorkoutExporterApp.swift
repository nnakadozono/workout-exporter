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
        guard let distanceSwimmingType = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
              let swimmingStrokeCountType = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount),
              let basalEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let healthKitTypeToRead: Set<HKObjectType> = [
            distanceSwimmingType,
            swimmingStrokeCountType,
            basalEnergyBurnedType,
            activeEnergyBurnedType,
            heartRateType,
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
        
//        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 3, sortDescriptors: [sortDescriptor]) { // Debug

            (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                // error handling
                print("Failed to fetch workouts: \(error?.localizedDescription ?? "Unknown error")")
                completion("")
                return
            }

             guard let distanceSwimmingType = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
                   let swimmingStrokeCountType = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount),
                   let basalEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
                   let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
                   let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                 fatalError("QuantityType(s) are unavailable.")
             }

            for workout in workouts.prefix(1) {
                print("\(workout.workoutActivityType), \(workout.duration),                       \(workout.sourceRevision), \(String(describing: workout.device)), \(String(describing: workout.device?.name)), \(String(describing: workout.device?.hardwareVersion)), \(workout.startDate), \(workout.endDate), \n\n \(String(describing: workout.metadata)), \n\n \(workout.allStatistics)")
                print("\n\n")
                print("\(String(describing: workout.workoutEvents))")
                
                guard let workoutEvents = workout.workoutEvents else {
                    print("No events available for this workout")
                    continue
                }
                for event in workoutEvents {
                    switch event.type {
                    case .lap:
                        print("lap")
                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                    case .segment:
                        print("segment")
                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                    default:
                        print("default")
                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                    }
                }

            }
            
            let jsonData = self.convertToJsonData(workouts)
            completion(jsonData)
//            completion("")
        }
        
        self.healthStore.execute(query)
    }
    
    private func convertToJsonData(_ workouts: [HKWorkout]) -> String {
        var jsonObject = [String: Any]()

        guard let distanceSwimmingType = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
              let swimmingStrokeCountType = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount),
              let basalEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            fatalError("QuantityType(s) are unavailable.")
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        
        var summaryArray = [Any]()
        var eventSegmentArray = [Any]()
        var eventLapArray = [Any]()
        for workout in workouts.prefix(3) {
            // workout for workoutSummary
            var workoutData = [String: Any]()
            
            workoutData["workoutActivityType"] = workout.workoutActivityType.rawValue
            workoutData["duration"] = workout.duration
            // workoutData["sourceRevision"] = workout.sourceRevision
            // workoutData["device"] = workout.device
            workoutData["startDate"] = dateFormatter.string(from: workout.startDate)
            workoutData["endDate"] = dateFormatter.string(from: workout.endDate)
            
            workoutData["DistanceSwimming_sum"] = workout.statistics(for: distanceSwimmingType)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            workoutData["SwimmingStrokeCount_sum"] = workout.statistics(for: swimmingStrokeCountType)?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            workoutData["BasalEnergyBurned_sum"] = workout.statistics(for: basalEnergyBurnedType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            workoutData["ActiveEnergyBurned_sum"] = workout.statistics(for: activeEnergyBurnedType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            workoutData["HeartRate_average"] = workout.statistics(for: heartRateType)?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            workoutData["HeartRate_minimum"] = workout.statistics(for: heartRateType)?.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            workoutData["HeartRate_maximum"] = workout.statistics(for: heartRateType)?.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0

            if let metadata = workout.metadata {
                for (key, value) in metadata {
                    if let dateValue = value as? Date {
                        workoutData[key] = dateFormatter.string(from: dateValue)
                    } else if let numberValue = value as? NSNumber {
                        workoutData[key] = numberValue
                    } else if let stringValue = value as? String {
                        workoutData[key] = stringValue
                    } else {
                        print("Unsupported type for key \(key): \(type(of: value))")
                    }
                }
            }
            summaryArray.append(workoutData)
            
            
            // workoutEvents for eventSegment and eventLap
            guard let workoutEvents = workout.workoutEvents else {
                print("No events available for this workout")
                continue
            }
            for event in workoutEvents {
                var eventData = [String: Any]()
                switch event.type {
                case .segment:
                    print("segment")
                    print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                    
                    eventData["start"] = dateFormatter.string(from: event.dateInterval.start)
                    eventData["end"] = dateFormatter.string(from: event.dateInterval.end)
                    eventData["duration"] = event.dateInterval.duration
                    if let eventMetadata = event.metadata {
                        for (key, value) in eventMetadata {
                            if let dateValue = value as? Date {
                                eventData[key] = dateFormatter.string(from: dateValue)
                            } else if let numberValue = value as? NSNumber {
                                eventData[key] = numberValue
                            } else if let stringValue = value as? String {
                                eventData[key] = stringValue
                            } else {
                                print("Unsupported type for key \(key): \(type(of: value))")
                            }
                        }
                    }
                    eventSegmentArray.append(eventData)
                case .lap:
                    print("lap")
                    print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                    eventData["start"] = dateFormatter.string(from: event.dateInterval.start)
                    eventData["end"] = dateFormatter.string(from: event.dateInterval.end)
                    eventData["duration"] = event.dateInterval.duration
                    if let eventMetadata = event.metadata {
                        for (key, value) in eventMetadata {
                            if let dateValue = value as? Date {
                                eventData[key] = dateFormatter.string(from: dateValue)
                            } else if let numberValue = value as? NSNumber {
                                eventData[key] = numberValue
                            } else if let stringValue = value as? String {
                                eventData[key] = stringValue
                            } else {
                                print("Unsupported type for key \(key): \(type(of: value))")
                            }
                        }
                    }
                    eventLapArray.append(eventData)
                default:
                    print("default")
                    print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                }
            }
        }
        jsonObject["workoutSummary"] = summaryArray
        jsonObject["workoutEventSegment"] = eventSegmentArray
        jsonObject["workoutEventLap"] = eventLapArray
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options:[JSONSerialization.WritingOptions.prettyPrinted])
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
