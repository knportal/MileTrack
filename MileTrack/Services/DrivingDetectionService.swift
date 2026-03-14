import CoreMotion
import Foundation

protocol DrivingDetectionServiceDelegate: AnyObject {
  func drivingDetectionDidStartDriving(_ service: DrivingDetectionService, at date: Date)
  func drivingDetectionDidStopDriving(_ service: DrivingDetectionService, at date: Date)
  func drivingDetectionDidUpdateAuthorization(_ service: DrivingDetectionService, status: CMAuthorizationStatus)
  
  // NEW: Motion confidence for GPS validation
  func drivingDetectionDidUpdateMotionConfidence(_ service: DrivingDetectionService, confidence: Double)
}

// Default implementation for optional delegate
extension DrivingDetectionServiceDelegate {
  func drivingDetectionDidUpdateMotionConfidence(_ service: DrivingDetectionService, confidence: Double) {}
}

/// Enhanced automotive activity detector using CoreMotion with device motion support.
@MainActor
final class DrivingDetectionService {
  weak var delegate: DrivingDetectionServiceDelegate?

  private let activityManager: CMMotionActivityManager
  private let motionManager: CMMotionManager
  private let queue: OperationQueue

  private(set) var isRunning: Bool = false
  private(set) var isDriving: Bool = false
  private(set) var motionConfidence: Double = 0.0  // 0-1 scale

  // Motion detection thresholds
  private let vehicleAccelMin: Double = 0.3  // Minimum sustained acceleration
  private let vehicleAccelMax: Double = 2.0  // Maximum to exclude walking/running
  private let stationaryThreshold: Double = 0.05  // Near-zero motion
  
  private var recentAccelerationSamples: [Double] = []
  private let sampleWindow: Int = 20  // 2 seconds at 10 Hz

  init(
    activityManager: CMMotionActivityManager = CMMotionActivityManager(),
    motionManager: CMMotionManager = CMMotionManager(),
    queue: OperationQueue = {
      let q = OperationQueue()
      q.name = "DrivingDetectionServiceQueue"
      q.qualityOfService = .utility
      return q
    }()
  ) {
    self.activityManager = activityManager
    self.motionManager = motionManager
    self.queue = queue
  }

  nonisolated var authorizationStatus: CMAuthorizationStatus {
    CMMotionActivityManager.authorizationStatus()
  }

  func start() {
    guard CMMotionActivityManager.isActivityAvailable() else { return }
    guard !isRunning else { return }
    isRunning = true

    delegate?.drivingDetectionDidUpdateAuthorization(self, status: authorizationStatus)

    // Start activity monitoring (coarse automotive detection)
    activityManager.startActivityUpdates(to: queue) { [weak self] activity in
      guard let self else { return }
      let status = self.authorizationStatus
      
      Task { @MainActor in
        self.delegate?.drivingDetectionDidUpdateAuthorization(self, status: status)
        
        guard let activity else { return }
        
        // MVP: treat "automotive" as driving. Ignore unknown.
        if activity.automotive {
          if !self.isDriving {
            self.isDriving = true
            self.delegate?.drivingDetectionDidStartDriving(self, at: Date())
          }
        } else if activity.stationary || activity.walking || activity.running || activity.cycling {
          if self.isDriving {
            self.isDriving = false
            self.delegate?.drivingDetectionDidStopDriving(self, at: Date())
          }
        }
      }
    }
    
    // Start device motion monitoring (fine-grained confidence scoring)
    startDeviceMotionMonitoring()
  }

  func stop() {
    guard isRunning else { return }
    isRunning = false
    activityManager.stopActivityUpdates()
    motionManager.stopDeviceMotionUpdates()
    isDriving = false
    motionConfidence = 0.0
    recentAccelerationSamples.removeAll()
  }
  
  // MARK: - Device Motion Monitoring
  
  private func startDeviceMotionMonitoring() {
    guard motionManager.isDeviceMotionAvailable else { return }
    
    motionManager.deviceMotionUpdateInterval = 0.1  // 10 Hz
    motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
      guard let self = self, let motion = motion else { return }
      
      Task { @MainActor in
        self.processDeviceMotion(motion)
      }
    }
  }
  
  private func processDeviceMotion(_ motion: CMDeviceMotion) {
    // Calculate user acceleration magnitude (removes gravity)
    let accel = motion.userAcceleration
    let accelMagnitude = sqrt(
      pow(accel.x, 2) +
      pow(accel.y, 2) +
      pow(accel.z, 2)
    )
    
    // Track recent samples for smoothing
    recentAccelerationSamples.append(accelMagnitude)
    if recentAccelerationSamples.count > sampleWindow {
      recentAccelerationSamples.removeFirst()
    }
    
    // Calculate average acceleration over window
    let avgAccel = recentAccelerationSamples.reduce(0, +) / Double(recentAccelerationSamples.count)
    
    // Rotation (turning) also indicates vehicle motion
    let rotation = motion.rotationRate
    let yawRate = abs(rotation.z)  // Primary turning axis
    
    // Calculate motion confidence score (0-1)
    var confidence = 0.0
    
    // Component 1: Sustained acceleration in vehicle range (0-0.6)
    if avgAccel >= vehicleAccelMin && avgAccel <= vehicleAccelMax {
      confidence += min(0.6, avgAccel / vehicleAccelMax * 0.6)
    }
    
    // Component 2: Rotation/turning (0-0.4)
    if yawRate > 0.05 {  // Typical car turning
      confidence += min(0.4, yawRate * 0.8)
    }
    
    // Cap at 1.0
    motionConfidence = min(1.0, confidence)
    
    // Notify delegate of updated confidence
    delegate?.drivingDetectionDidUpdateMotionConfidence(self, confidence: motionConfidence)
  }
  
  // MARK: - Public Helpers
  
  /// Returns true if current motion patterns suggest the device is stationary
  var isLikelyStationary: Bool {
    guard recentAccelerationSamples.count >= sampleWindow / 2 else { return false }
    let avgAccel = recentAccelerationSamples.reduce(0, +) / Double(recentAccelerationSamples.count)
    return avgAccel < stationaryThreshold
  }
  
  /// Returns true if current motion patterns suggest vehicle motion
  var isLikelyVehicleMotion: Bool {
    return motionConfidence > 0.3
  }
}

