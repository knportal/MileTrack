import Combine
import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class ReceiptsStore: ObservableObject {
  @Published var receipts: [TripReceipt]
  @Published var lastSaveError: String?
  
  private let persistence: ReceiptsPersistenceStore
  private var cancellables: Set<AnyCancellable> = []
  
  init(
    receipts: [TripReceipt]? = nil,
    persistence: ReceiptsPersistenceStore? = nil
  ) {
    let persistenceStore = persistence ?? ReceiptsPersistenceStore()
    self.persistence = persistenceStore
    
    if let receipts {
      self.receipts = receipts
    } else if let loaded = try? persistenceStore.loadReceipts() {
      self.receipts = loaded
    } else {
      self.receipts = []
    }
    
    $receipts
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }
  
  /// Get all receipts for a specific trip
  func receipts(for trip: Trip) -> [TripReceipt] {
    receipts.filter { $0.tripId == trip.id }
  }
  
  /// Get all receipts for multiple trips
  func receipts(for trips: [Trip]) -> [TripReceipt] {
    let tripIds = Set(trips.map { $0.id })
    return receipts.filter { tripIds.contains($0.tripId) }
  }
  
  /// Calculate total receipt amount for a trip
  func totalAmount(for trip: Trip) -> Decimal {
    receipts(for: trip).reduce(Decimal(0)) { sum, receipt in
      sum + (receipt.amount ?? 0)
    }
  }
  
  /// Add a new receipt
  func add(_ receipt: TripReceipt) {
    receipts.append(receipt)
  }
  
  #if canImport(UIKit)
  /// Add a receipt with an image
  func add(_ receipt: TripReceipt, image: UIImage) throws {
    var updatedReceipt = receipt
    
    // Save image if provided
    if let imageData = image.jpegData(compressionQuality: 0.8) {
      let fileName = "\(receipt.id.uuidString).jpg"
      let savedFileName = try persistence.saveImage(imageData, fileName: fileName)
      updatedReceipt.imageFileName = savedFileName
    }
    
    receipts.append(updatedReceipt)
  }
  #endif
  
  /// Update an existing receipt
  func update(_ receipt: TripReceipt) -> Bool {
    guard let idx = receipts.firstIndex(where: { $0.id == receipt.id }) else {
      return false
    }
    receipts[idx] = receipt
    return true
  }
  
  #if canImport(UIKit)
  /// Update a receipt and optionally update its image
  func update(_ receipt: TripReceipt, image: UIImage?) throws -> Bool {
    guard let idx = receipts.firstIndex(where: { $0.id == receipt.id }) else {
      return false
    }
    
    var updatedReceipt = receipt
    
    // Handle image update
    if let image = image {
      // Delete old image if it exists
      if let oldFileName = receipts[idx].imageFileName {
        try? persistence.deleteImage(fileName: oldFileName)
      }
      
      // Save new image
      if let imageData = image.jpegData(compressionQuality: 0.8) {
        let fileName = "\(receipt.id.uuidString).jpg"
        let savedFileName = try persistence.saveImage(imageData, fileName: fileName)
        updatedReceipt.imageFileName = savedFileName
      }
    }
    
    receipts[idx] = updatedReceipt
    return true
  }
  #endif
  
  /// Remove a receipt
  func remove(_ receipt: TripReceipt) throws {
    // Delete associated image if it exists
    if let fileName = receipt.imageFileName {
      try? persistence.deleteImage(fileName: fileName)
    }
    
    receipts.removeAll { $0.id == receipt.id }
  }
  
  /// Remove all receipts for a specific trip
  func removeReceipts(for trip: Trip) throws {
    let tripReceipts = receipts(for: trip)
    
    // Delete all associated images
    for receipt in tripReceipts {
      if let fileName = receipt.imageFileName {
        try? persistence.deleteImage(fileName: fileName)
      }
    }
    
    receipts.removeAll { $0.tripId == trip.id }
  }
  
  #if canImport(UIKit)
  /// Load image for a receipt
  func loadImage(for receipt: TripReceipt) -> UIImage? {
    guard let fileName = receipt.imageFileName else { return nil }
    guard let imageData = try? persistence.loadImage(fileName: fileName) else { return nil }
    return UIImage(data: imageData)
  }
  #endif
  
  func saveNow() {
    persist(receipts)
  }
  
  private func persist(_ value: [TripReceipt]) {
    do {
      try persistence.saveReceipts(value)
      lastSaveError = nil
    } catch {
      lastSaveError = "Failed to save receipts: \(error.localizedDescription)"
    }
  }
}
