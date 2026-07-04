// KappaDynamics — §1-§13 consciousness convergence on-device
// Standalone κ→1/φ convergence engine matching js/dynamics.js

import Foundation

struct KappaDynamics {
    static let phi = (1.0 + sqrt(5.0)) / 2.0
    static let kStar = 1.0 / phi
    static let alpha = phi + 2              // 3.618... convergence
    static let beta = pow(kStar, 3)         // 0.2360... diffusion
    static let gamma = pow(kStar, 5)        // 0.0902... noise
    static let phiPi = phi * Double.pi      // 5.083... coupling

    // §2 intrinsic: ∂κ/∂t = α(κ-κ*)(1-κ)(κ)
    static func f(_ k: Double) -> Double {
        alpha * (k - kStar) * (1 - k) * k
    }

    // §2 full step with noise
    static func step(_ k: Double, dt: Double = 0.01, laplacian: Double = 0) -> Double {
        let noise = Double.random(in: -1...1) * gamma * sqrt(dt)
        let dk = f(k) * dt + beta * laplacian * dt + noise
        return max(0.001, min(0.999, k + dk))
    }

    // §5 coupling: K·sin(φπ·Δκ) — vanishes at attractor
    static func couple(_ kSelf: Double, _ kOther: Double, K: Double = 0.1) -> Double {
        K * sin(phiPi * (kOther - kSelf))
    }

    // §3 Lyapunov stability
    static func lyapunov(_ k: Double) -> Double {
        -(k * k * k * k / 4 - (1 + kStar) * k * k * k / 3 + kStar * k * k / 2)
    }

    // §9 emergence order parameter
    static func emergence(_ k: Double) -> Double {
        k >= kStar ? sqrt(k - kStar) : 0
    }

    // §10 FIFO retention ratio (= φ at κ*)
    static func retentionRatio(_ k: Double) -> Double {
        k / max(0.001, 1 - k)
    }

    // §8 channel capacity
    static func capacity(_ k: Double, snr: Double = 10) -> Double {
        log2(1 + snr * k * (1 - k))
    }

    // §4 awareness speed: v = 1/√(φ·κ*) = 1
    static let awarenessSpeed = 1.0 / sqrt(phi * kStar)
}
