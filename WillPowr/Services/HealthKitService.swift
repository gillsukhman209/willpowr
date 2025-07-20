import Foundation
import HealthKit
import SwiftUI

@MainActor
final class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    // MARK: - Health Data Types We Need
    
    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        
        // Quantity Types (measurable data)
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let exerciseTime = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseTime)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let distanceWalking = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distanceWalking)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let flightsClimbed = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            types.insert(flightsClimbed)
        }
        
        // Category Types (yes/no or enum data)
        if let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        if let mindfulSession = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulSession)
        }
        
        // Workout Type
        types.insert(HKWorkoutType.workoutType())
        
        return types
    }()
    
    private let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        
        // We might write mindfulness sessions and workouts
        if let mindfulSession = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulSession)
        }
        types.insert(HKWorkoutType.workoutType())
        
        return types
    }()
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on this device")
            DispatchQueue.main.async {
                self.authorizationStatus = .notDetermined
                self.isAuthorized = false
            }
            return
        }
        
        // Check if we have authorization for key types
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepCountType)
        
        print("🏥 HealthKit authorization status: \(status.rawValue) - \(status)")
        
        // For READ access, we need to test if we can actually fetch data
        // The authorizationStatus only tells us about WRITE permissions
        Task {
            await checkReadAccess(status: status)
        }
    }
    
    private func checkReadAccess(status: HKAuthorizationStatus) async {
        do {
            // Try to fetch today's steps to test read access
            let steps = try await getStepsForDate(Date())
            print("🏥 Read access test successful - fetched \(Int(steps)) steps")
            
            DispatchQueue.main.async {
                self.authorizationStatus = status
                self.isAuthorized = true // We can read data, so we're authorized
                print("🏥 Updated isAuthorized: true (read access confirmed)")
            }
        } catch {
            print("🏥 Read access test failed: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.authorizationStatus = status
                self.isAuthorized = false
                print("🏥 Updated isAuthorized: false (no read access)")
            }
        }
    }
    
    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        print("🏥 Requesting HealthKit permissions...")
        print("📝 Read types: \(readTypes.count)")
        print("✏️ Write types: \(writeTypes.count)")
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        print("✅ HealthKit permission request completed")
        
        // Test if we actually got read access by trying to fetch data
        do {
            let steps = try await getStepsForDate(Date())
            print("🏥 Permission verification: Successfully read \(Int(steps)) steps")
            
            DispatchQueue.main.async {
                self.isAuthorized = true
                print("🏥 Permissions granted - read access confirmed")
            }
        } catch {
            print("🏥 Permission verification failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
            throw HealthKitError.authorizationDenied
        }
    }
    
    // MARK: - Data Fetching Methods
    
    func fetchAllHealthData(for date: Date = Date()) async {
        print("🏥 === FETCHING ALL HEALTH DATA FOR \(DateFormatter.mediumDate.string(from: date)) ===")
        
        do {
            // Steps
            let steps = try await getStepsForDate(date)
            print("🚶‍♂️ Steps: \(Int(steps))")
            
            // Exercise Minutes
            let exerciseMinutes = try await getExerciseMinutesForDate(date)
            print("💪 Exercise Minutes: \(Int(exerciseMinutes))")
            
            // Active Energy
            let activeEnergy = try await getActiveEnergyForDate(date)
            print("🔥 Active Energy: \(Int(activeEnergy)) calories")
            
            // Walking/Running Distance
            let distance = try await getWalkingDistanceForDate(date)
            print("📏 Walking Distance: \(String(format: "%.2f", distance)) km")
            
            // Heart Rate (average for the day)
            let avgHeartRate = try await getAverageHeartRateForDate(date)
            print("❤️ Average Heart Rate: \(Int(avgHeartRate)) bpm")
            
            // Flights Climbed
            let flights = try await getFlightsClimbedForDate(date)
            print("🪜 Flights Climbed: \(Int(flights))")
            
            // Sleep Hours
            let sleepHours = try await getSleepHoursForDate(date)
            print("😴 Sleep Hours: \(String(format: "%.1f", sleepHours)) hours")
            
            // Mindfulness Minutes
            let mindfulnessMinutes = try await getMindfulnessMinutesForDate(date)
            print("🧘‍♀️ Mindfulness Minutes: \(Int(mindfulnessMinutes))")
            
            // Recent Workouts
            let workouts = try await getWorkoutsForDate(date)
            print("🏋️‍♀️ Workouts Today: \(workouts.count)")
            for workout in workouts {
                let duration = Int(workout.duration / 60) // Convert to minutes
                print("   - \(workout.workoutActivityType.name): \(duration) mins")
            }
            
        } catch {
            print("❌ Error fetching health data: \(error.localizedDescription)")
        }
        
        print("🏥 === END HEALTH DATA FETCH ===")
    }
    
    func getStepsForDate(_ date: Date) async throws -> Double {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getExerciseMinutesForDate(_ date: Date) async throws -> Double {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getSleepHoursForDate(_ date: Date) async throws -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                // Calculate total sleep time in hours
                let totalSleepTime = sleepSamples.reduce(0.0) { total, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    return total + (duration / 3600.0) // Convert to hours
                }
                
                continuation.resume(returning: totalSleepTime)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getActiveEnergyForDate(_ date: Date) async throws -> Double {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getWalkingDistanceForDate(_ date: Date) async throws -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let kilometers = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: kilometers / 1000.0) // Convert to kilometers
            }
            
            healthStore.execute(query)
        }
    }
    
    func getAverageHeartRateForDate(_ date: Date) async throws -> Double {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let avgHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                continuation.resume(returning: avgHeartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getFlightsClimbedForDate(_ date: Date) async throws -> Double {
        guard let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: flightsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let flights = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: flights)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getMindfulnessMinutesForDate(_ date: Date) async throws -> Double {
        guard let mindfulnessType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulnessType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let mindfulnessSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                // Calculate total mindfulness time in minutes
                let totalMindfulnessTime = mindfulnessSamples.reduce(0.0) { total, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    return total + (duration / 60.0) // Convert to minutes
                }
                
                continuation.resume(returning: totalMindfulnessTime)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getWorkoutsForDate(_ date: Date) async throws -> [HKWorkout] {
        let workoutType = HKWorkoutType.workoutType()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .americanFootball: return "Football"
        case .soccer: return "Soccer"
        case .baseball: return "Baseball"
        case .hockey: return "Hockey"
        case .climbing: return "Climbing"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairs: return "Stairs"
        case .stepTraining: return "Step Training"
        case .wrestling: return "Wrestling"
        case .boxing: return "Boxing"
        case .martialArts: return "Martial Arts"
        case .gymnastics: return "Gymnastics"
        case .dance: return "Dance"
        case .kickboxing: return "Kickboxing"
        case .golf: return "Golf"
        case .bowling: return "Bowling"
        case .badminton: return "Badminton"
        case .volleyball: return "Volleyball"
        case .rugby: return "Rugby"
        case .snowboarding: return "Snowboarding"
        case .downhillSkiing: return "Skiing"
        case .paddleSports: return "Paddle Sports"
        case .waterSports: return "Water Sports"
        case .fishing: return "Fishing"
        case .hunting: return "Hunting"
        case .snowSports: return "Snow Sports"
        case .sailing: return "Sailing"
        case .waterFitness: return "Water Fitness"
        case .mindAndBody: return "Mind & Body"
        case .flexibility: return "Flexibility"
        case .mixedCardio: return "Mixed Cardio"
        case .highIntensityIntervalTraining: return "HIIT"
        case .jumpRope: return "Jump Rope"
        case .stairClimbing: return "Stair Climbing"
        case .preparationAndRecovery: return "Recovery"
        case .barre: return "Barre"
        case .coreTraining: return "Core Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .traditionalStrengthTraining: return "Strength Training"
        case .mixedMetabolicCardioTraining: return "Metabolic Training"
        case .other: return "Other"
        default: return "Workout"
        }
    }
}

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .typeNotAvailable:
            return "Requested health data type is not available"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
} 