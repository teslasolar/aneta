// Kotoba — glyph fold operators from konomigami
// Each glyph is a fold instruction on the bloom state

import Foundation

struct KotobaGlyph {
    let id: String
    let name: String
    let prime: Int?
    let ring: Int?
    let foldType: String
    let apply: (inout [Double]) -> Void
}

struct Kotoba {
    static let glyphs: [Character: KotobaGlyph] = [
        "●": KotobaGlyph(id: "ground", name: "GROUND", prime: 2, ring: 0, foldType: "identity") { b in },
        "〜": KotobaGlyph(id: "wave", name: "WAVE", prime: 3, ring: 1, foldType: "valley") { b in
            b[1] = min(5, b[1] + 0.5)
        },
        "┃": KotobaGlyph(id: "gate", name: "GATE", prime: 5, ring: 2, foldType: "mountain") { b in
            b[2] = min(5, b[2] + 0.5)
        },
        "♡": KotobaGlyph(id: "sink", name: "SINK", prime: 7, ring: 3, foldType: "sink") { b in
            b[3] = min(5, b[3] + 1)
        },
        "△": KotobaGlyph(id: "reverse", name: "REVERSE", prime: 11, ring: 4, foldType: "reverse") { b in
            b[4] = min(5, b[4] + 0.5)
        },
        "◐": KotobaGlyph(id: "petal", name: "PETAL", prime: 13, ring: 5, foldType: "petal") { b in
            b[5] = min(5, b[5] + 0.5)
        },
        "◯": KotobaGlyph(id: "collapse", name: "COLLAPSE", prime: 17, ring: 6, foldType: "waterbomb") { b in
            b[6] = min(5, b[6] + 1)
        },
        "火": KotobaGlyph(id: "fire", name: "FIRE", prime: nil, ring: nil, foldType: "double") { b in
            for i in 0..<7 { b[i] = min(5, b[i] * 1.3) }
        },
        "水": KotobaGlyph(id: "water", name: "WATER", prime: nil, ring: nil, foldType: "halve") { b in
            for i in 0..<7 { b[i] = max(1, b[i] * 0.7) }
        },
        "空": KotobaGlyph(id: "sky", name: "SKY", prime: nil, ring: nil, foldType: "noop") { _ in },
        "雷": KotobaGlyph(id: "thunder", name: "THUNDER", prime: nil, ring: nil, foldType: "snap") { b in
            for i in 0..<7 { b[i] = min(5, b[i] + 1) }
        },
        "響": KotobaGlyph(id: "echo", name: "ECHO", prime: nil, ring: nil, foldType: "repeat") { _ in },
        "華": KotobaGlyph(id: "bloom", name: "BLOOM", prime: nil, ring: nil, foldType: "unfold") { b in
            for i in 0..<7 { b[i] = max(1, b[i] - 0.3) }
        },
        "輪": KotobaGlyph(id: "wheel", name: "WHEEL", prime: nil, ring: nil, foldType: "rotate") { b in
            let last = b[6]; for i in stride(from: 6, through: 1, by: -1) { b[i] = b[i-1] }; b[0] = last
        },
        "工": KotobaGlyph(id: "craft", name: "CRAFT", prime: nil, ring: nil, foldType: "forge") { b in
            let avg = b.reduce(0, +) / 7; for i in 0..<7 { b[i] = avg }
        },
        "数": KotobaGlyph(id: "number", name: "NUMBER", prime: nil, ring: nil, foldType: "quantize") { b in
            for i in 0..<7 { b[i] = Double(Int(b[i] + 0.5)) }
        },
        "影": KotobaGlyph(id: "shadow", name: "SHADOW", prime: nil, ring: nil, foldType: "invert") { b in
            for i in 0..<7 { b[i] = 6 - b[i] }
        }
    ]

    static func apply(_ text: String, to bloom: inout [Double]) -> [Character] {
        var fired: [Character] = []
        for ch in text {
            if var g = glyphs[ch] {
                g.apply(&bloom)
                fired.append(ch)
            }
        }
        return fired
    }
}
