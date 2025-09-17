import Foundation
import UIKit

final class ImageCache {
    // MARK: - Node for LRU linked list
    private class DoublyLinkedNode {
        let key: Int
        var prev: DoublyLinkedNode?
        var next: DoublyLinkedNode?
        
        init(key: Int) {
            self.key = key
        }
    }
    
    // MARK: - Properties
    static let shared = ImageCache()
    
    private let cache = NSCache<NSNumber, UIImage>()
    private var maxItems: Int
    private var maxCost: Int
    
    // LRU tracking
    private var nodes: [Int: DoublyLinkedNode] = [:]
    private var head: DoublyLinkedNode? // Most recently used
    private var tail: DoublyLinkedNode? // Least recently used
    
    // Current tracking
    private var currentItems: Int = 0
    private var currentCost: Int = 0
    
    // Synchronization queue
    private let syncQueue = DispatchQueue(label: "com.imagecache.syncqueue")
    
    // MARK: - Init
    init(maxItems: Int = 100, maxCost: Int = 50 * 1024 * 1024) {
        self.maxItems = maxItems
        self.maxCost = maxCost
        cache.countLimit = maxItems
        cache.totalCostLimit = maxCost
    }
    
    // MARK: - Public API
    
    /// Returns cached image for index, if exists. Updates LRU.
    func image(for index: Int) -> UIImage? {
        syncQueue.sync {
            guard let image = cache.object(forKey: NSNumber(value: index)),
                  let node = nodes[index] else {
                return nil
            }
            
            // Move accessed node to head (most recently used)
            moveToHead(node)
            return image
        }
    }
    
    /// Sets image for index with given cost. Updates LRU and evicts if needed.
    func setImage(_ image: UIImage, for index: Int, cost: Int) {
        syncQueue.sync {
            let key = index
            let nsKey = NSNumber(value: key)
            
            if let existingNode = nodes[key] {
                // Update cost
                cache.setObject(image, forKey: nsKey, cost: cost)
                currentCost -= cacheCost(for: existingNode.key)
                currentCost += cost
                // Move node to head
                moveToHead(existingNode)
            } else {
                // New node
                let node = DoublyLinkedNode(key: key)
                nodes[key] = node
                insertAtHead(node)
                currentItems += 1
                currentCost += cost
                cache.setObject(image, forKey: nsKey, cost: cost)
            }
            
            // Evict if over limits
            evictIfNeeded()
        }
    }
    
    /// Removes all cached images and LRU tracking
    func removeAll() {
        syncQueue.sync {
            cache.removeAllObjects()
            nodes.removeAll()
            head = nil
            tail = nil
            currentItems = 0
            currentCost = 0
        }
    }
    
    // MARK: - Helper
    
    /// Estimates approximate memory cost in bytes for image based on pixel count
    static func estimatedCost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4
    }
    
    // MARK: - Private methods
    
    private func cacheCost(for key: Int) -> Int {
        guard let image = cache.object(forKey: NSNumber(value: key)) else { return 0 }
        return Self.estimatedCost(for: image)
    }
    
    // Move existing node to head of linked list
    private func moveToHead(_ node: DoublyLinkedNode) {
        guard head !== node else { return }
        // Remove node from current position
        removeNode(node)
        // Insert at head
        insertAtHead(node)
    }
    
    // Insert a node at the head of the linked list
    private func insertAtHead(_ node: DoublyLinkedNode) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }
    
    // Remove a node from linked list
    private func removeNode(_ node: DoublyLinkedNode) {
        let prev = node.prev
        let next = node.next
        
        if let prev = prev {
            prev.next = next
        } else {
            // Node is head
            head = next
        }
        if let next = next {
            next.prev = prev
        } else {
            // Node is tail
            tail = prev
        }
        
        node.prev = nil
        node.next = nil
    }
    
    // Evict nodes from tail until under limits
    private func evictIfNeeded() {
        while currentItems > maxItems || currentCost > maxCost {
            guard let tailNode = tail else { break }
            removeNode(tailNode)
            nodes.removeValue(forKey: tailNode.key)
            let nsKey = NSNumber(value: tailNode.key)
            let cost = cacheCost(for: tailNode.key)
            cache.removeObject(forKey: nsKey)
            currentItems -= 1
            currentCost -= cost
        }
    }
}
