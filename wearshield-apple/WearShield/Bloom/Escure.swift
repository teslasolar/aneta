// Escure — prime cascade validation from konomigami
// Checks a fold number against Mersenne prime bit widths

import Foundation

struct Escure {
    static let mersenne: [Int: Int] = [2: 3, 3: 7, 5: 31, 7: 127, 11: 2047, 13: 8191, 17: 131071]

    static func validate(_ n: Int) -> (ok: Bool, failures: [Int]) {
        var fails: [Int] = []
        for (p, m) in mersenne {
            if n % m == 0 { fails.append(p) }
        }
        return (fails.isEmpty, fails)
    }

    static func foldSignature(_ bloom: [Int]) -> String {
        bloom.enumerated().map { (i, e) in
            let p = [2, 3, 5, 7, 11, 13, 17][i]
            return "\(p)^\(e)"
        }.joined(separator: "·")
    }

    static func primorial(_ bloom: [Int]) -> Int {
        let primes = [2, 3, 5, 7, 11, 13, 17]
        var f = 1
        for (i, e) in bloom.enumerated() where i < primes.count {
            let pw = Int(pow(Double(primes[i]), Double(e)))
            if f > Int.max / max(1, pw) { return Int.max }
            f *= pw
        }
        return f
    }
}
