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

    func dateRange(forPeriod period: String) -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case "Past Two Weeks":
            let startDate = calendar.date(byAdding: .day, value: -13, to: now)!
            return (startDate, now)
        case "This Year":
            let startDate = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (startDate, now)
        case "Last and This Year":
            let startOfThisYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: startOfThisYear)!
            return (startOfLastYear, now)
        case "All Time":
            return (Date.distantPast, Date.distantFuture)
        default:
            return nil
        }
        
    }
    
    func fetchSwimmingWorkouts(forPeriod period: String, completion: @escaping ([HKWorkout]?) -> Void){
        guard let range = dateRange(forPeriod: period) else {
            completion(nil)
            return
        }
        let datePredicate = HKQuery.predicateForSamples(withStart: range.startDate, end: range.endDate, options: .strictStartDate)
        let workoutTypePredicate = HKQuery.predicateForWorkouts(with: .swimming)
        let workoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, workoutTypePredicate])
       
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
//        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 3, sortDescriptors: [sortDescriptor]) { // Debug

            (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                // error handling
                print("Failed to fetch workouts: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

//             guard let distanceSwimmingType = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
//                   let swimmingStrokeCountType = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount),
//                   let basalEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
//                   let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
//                   let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
//                 fatalError("QuantityType(s) are unavailable.")
//             }
//
//            for workout in workouts.prefix(1) {
//                print("\(workout.workoutActivityType), \(workout.duration),                       \(workout.sourceRevision), \(String(describing: workout.device)), \(String(describing: workout.device?.name)), \(String(describing: workout.device?.hardwareVersion)), \(workout.startDate), \(workout.endDate), \n\n \(String(describing: workout.metadata)), \n\n \(workout.allStatistics)")
//                print("\n\n")
//                print("\(String(describing: workout.workoutEvents))")
//                
//                guard let workoutEvents = workout.workoutEvents else {
//                    print("No events available for this workout")
//                    continue
//                }
//                for event in workoutEvents {
//                    switch event.type {
//                    case .lap:
//                        print("lap")
//                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
//                    case .segment:
//                        print("segment")
//                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
//                    default:
//                        print("default")
//                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
//                    }
//                }
//
//            }
            
//            let jsonData = self.convertToJsonData(workouts)
//            completion(jsonData)
//            completion("")
            completion(workouts)
        }
        
        self.healthStore.execute(query)
    }
    
    
    
    
    func fetchData(for sampleType: HKQuantityType, forPeriod period: String, completion: @escaping ([HKQuantitySample]?) -> Void)
    {
        guard let range = dateRange(forPeriod: period) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: range.startDate, end: range.endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor] ) {
            (query, samples, error) in
            if let samples = samples as? [HKQuantitySample] {
                completion(samples)
            } else {
                completion(nil)
            }
        }
        self.healthStore.execute(query)
    }

    func fetchLapData(forPeriod period: String, completion: @escaping (String) -> Void) {
        guard let distanceSwimmingType = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
              let swimmingStrokeCountType = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount),
//              let basalEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
//              let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion("")
            return
        }
       
        let dispatchGroup = DispatchGroup()
        
//        var lapData = [String: [HKQuantitySample]]()
        var lapData = [String: [Any]]()
        
        fetchSwimmingWorkouts(forPeriod: period) { workouts in
            if let workouts: [HKWorkout] = workouts {
                lapData["workouts"] = workouts
            }
        }
        
        dispatchGroup.enter()
        fetchData(for: distanceSwimmingType, forPeriod: period) {samples in
            if let samples = samples {
//                print("\(distanceSwimmingType): \(String(describing: samples.first?.startDate)), \(String(describing: samples.first?.endDate)), \(String(describing: samples.first?.quantity.doubleValue(for: .meter())))")
                lapData["distanceSwimming"] = samples
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchData(for: swimmingStrokeCountType, forPeriod: period) {samples in
            if let samples = samples {
//                print("\(distanceSwimmingType): \(String(describing: samples.first?.startDate)), \(String(describing: samples.first?.endDate)), \(String(describing: samples.first?.quantity.doubleValue(for: .count())))")
                lapData["swimmingStrokeCount"] = samples
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchData(for: heartRateType, forPeriod: period) {samples in
            if let samples = samples {
//                print("\(heartRateType): \(String(describing: samples.first?.startDate)), \(String(describing: samples.first?.endDate)), \(String(describing: samples.first?.quantity.doubleValue(for: HKUnit(from: "count/min"))))")
                lapData["heartRate"] = samples
            }
            dispatchGroup.leave()
        }
//        completion("")
        dispatchGroup.notify(queue: .main) {
            let jsonData = self.convertToJsonData(lapData)
            completion(jsonData)
        }
    }
    
    private func convertToJsonData(_ lapData: [String: [Any]]) -> String {
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
        
        if let workouts = lapData["workouts"] as? [HKWorkout] {
            var summaryArray = [Any]()
            var eventSegmentArray = [Any]()
            var eventLapArray = [Any]()
            for workout in workouts {
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
                        } else if let quantity = value as? HKQuantity {
                            if key == "HKLapLength" {
                                workoutData[key] = quantity.doubleValue(for: .meter())
                            } else if key == "HKAverageMETs" {
                                let mets = HKUnit.kilocalorie().unitDivided(by: HKUnit.gramUnit(with: .kilo)).unitDivided(by: HKUnit.hour())
                                workoutData[key] = quantity.doubleValue(for: mets)
                            } else if key == "HKWeatherTemperature" {
                                workoutData[key] = quantity.doubleValue(for: .degreeCelsius())
                            } else if key == "HKWeatherHumidity" {
                                workoutData[key] = quantity.doubleValue(for: .percent())
                            } else if key == "HKWeatherHumidity" {
                                workoutData[key] = quantity.doubleValue(for: .percent())
                            } else {
                                print("Unsupported type for key \(key): \(type(of: value)), \(value)")
                            }
                        } else {
                            print("Unsupported type for key \(key): \(type(of: value)), \(value)")
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
//                        print("segment")
//                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                        
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
                                    print("Unsupported type for key \(key): \(type(of: value)), \(value)")
                                }
                            }
                        }
                        eventSegmentArray.append(eventData)
                    case .lap:
//                        print("lap")
//                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
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
                                    print("Unsupported type for key \(key): \(type(of: value)), \(value)")
                                }
                            }
                        }
                        eventLapArray.append(eventData)
                    default:
//                        print("default")
                        print("\(event.dateInterval.start), \(event.dateInterval.end), \(event.dateInterval.duration), \(String(describing: event.metadata))")
                    }
                }
            }
            jsonObject["workoutSummary"] = summaryArray
            jsonObject["workoutEventSegment"] = eventSegmentArray
            jsonObject["workoutEventLap"] = eventLapArray
        }

        var distanceSwimmingArray = [Any]()
        if let samples = lapData["distanceSwimming"] as? [HKQuantitySample] {
            for sample in samples {
//                print("distanceSwimming: \(String(describing: sample.startDate)), \(String(describing: sample.endDate)), \(String(describing: sample.quantity.doubleValue(for: .meter())))")
                var sampleData = [String: Any]()
                sampleData["startDate"] = dateFormatter.string(from: sample.startDate)
                sampleData["endDate"] = dateFormatter.string(from: sample.endDate)
                sampleData["value"] = sample.quantity.doubleValue(for: .meter())
                distanceSwimmingArray.append(sampleData)
            }
        }
        jsonObject["distanceSwimming"] = distanceSwimmingArray
                    
        var swimmingStrokeCountArray = [Any]()
        if let samples = lapData["swimmingStrokeCount"] as? [HKQuantitySample]  {
            for sample in samples {
                var sampleData = [String: Any]()
                sampleData["startDate"] = dateFormatter.string(from: sample.startDate)
                sampleData["endDate"] = dateFormatter.string(from: sample.endDate)
                sampleData["value"] = sample.quantity.doubleValue(for: .count())
                swimmingStrokeCountArray.append(sampleData)
            }
        }
        jsonObject["swimmingStrokeCount"] = swimmingStrokeCountArray
        

        var heartRateArray = [Any]()
        if let samples = lapData["heartRate"] as? [HKQuantitySample]  {
            for sample in samples {
                var sampleData = [String: Any]()
                sampleData["startDate"] = dateFormatter.string(from: sample.startDate)
                sampleData["endDate"] = dateFormatter.string(from: sample.endDate)
                sampleData["value"] = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                heartRateArray.append(sampleData)
            }
        }
        jsonObject["heartRate"] = heartRateArray

        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options:[JSONSerialization.WritingOptions.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Failed to convert to JSON")
            return ""
        }
    }
        
    func exportAndShareWorkout(for period: String) {
        //fetchSwimmingWorkouts { jsonData in
        fetchLapData(forPeriod: period) { jsonData in
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
