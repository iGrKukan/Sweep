import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UIKit

/// 64-bit difference hash (dHash) for fast near-duplicate detection.
///
/// The hash is computed from a 9×8 grayscale downscale by comparing each
/// pixel to its right neighbour; the resulting 64 bits live in a UInt64.
/// Hamming distance between two hashes ≤ 6 is a strong "near-duplicate" signal.
enum PerceptualHash {
    static let zero: UInt64 = 0

    /// Compute a dHash of the image. Returns 0 on failure.
    static func compute(_ image: UIImage) -> UInt64 {
        guard let cg = image.cgImage else { return 0 }
        return compute(cg)
    }

    static func compute(_ cg: CGImage) -> UInt64 {
        let width = 9
        let height = 8
        guard let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) else { return 0 }
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hash: UInt64 = 0
        var bit: UInt64 = 1
        for y in 0..<height {
            for x in 0..<(width - 1) {
                let left = pixels[y * width + x]
                let right = pixels[y * width + x + 1]
                if left > right { hash |= bit }
                bit <<= 1
            }
        }
        return hash
    }

    /// Hamming distance between two hashes (number of differing bits).
    static func distance(_ a: UInt64, _ b: UInt64) -> Int {
        (a ^ b).nonzeroBitCount
    }
}

/// Variance of Laplacian — classic blur metric. Lower = more blurry.
enum BlurMetric {
    static func variance(_ image: UIImage) -> Double {
        guard let cg = image.cgImage else { return .infinity }
        let width = 64
        let height = 64
        guard let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) else { return .infinity }
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return .infinity }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 3x3 Laplacian kernel: 0 -1 0 / -1 4 -1 / 0 -1 0
        var sum: Double = 0
        var sumSq: Double = 0
        var n = 0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let i = y * width + x
                let c = Int(pixels[i])
                let up = Int(pixels[i - width])
                let down = Int(pixels[i + width])
                let left = Int(pixels[i - 1])
                let right = Int(pixels[i + 1])
                let v = Double(4 * c - up - down - left - right)
                sum += v
                sumSq += v * v
                n += 1
            }
        }
        guard n > 0 else { return .infinity }
        let mean = sum / Double(n)
        return sumSq / Double(n) - mean * mean
    }
}
