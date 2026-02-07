import CoreMotion
import Foundation

protocol DrivingDetectionServiceDelegate: AnyObject {
  func drivingDetectionDidStartDriving(_ service: DrivingDetectionService, at date: Date)
  func drivingDetectionDidStopDriving(_ service: DrivingDetectionService, at date: Date)
  func drivingDetectionDidUpdateAuthorization(_ service: DrivingDetectionService, status: CMAuthorizationStatus)
}

/// Minimal automotive activity detector using CoreMotion.
final class DrivingDetectionService {
  weak var delegate: DrivingDetectionServiceDelegate?

  private let manager: CMMotionActivityManager
  private let queue: OperationQueue

  private(set) var isRunning: Bool = false
  private(set) var isDriving: Bool = false

  init(
    manager: CMMotionActivityManager = CMMotionActivityManager(),
    queue: OperationQueue = {
      let q = OperationQueue()
      q.name = "DrivingDetectionServiceQueue"
      q.qualityOfService = .utility
      return q
    }()
  ) {
    self.manager = manager
    self.queue = queue
  }

  var authorizationStatus: CMAuthorizationStatus {
    CMMotionActivityManager.authorizationStatus()
  }

  func start() {
    guard CMMotionActivityManager.isActivityAvailable() else { return }
    guard !isRunning else { return }
    isRunning = true

    delegate?.drivingDetectionDidUpdateAuthorization(self, status: authorizationStatus)

    manager.startActivityUpdates(to: queue) { [weak self] activity in
      guard let self else { return }
      let status = self.authorizationStatus
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

  func stop() {
    guard isRunning else { return }
    isRunning = false
    manager.stopActivityUpdates()
    isDriving = false
  }
}

