// Κ.KOTOBA — glyph state mutations
export const KOTO = {
  '●': { nm: 'ground', ring: 0, fn: s => { s.primary = 'bloomqr' } },
  '〜': { nm: 'wave', ring: 1, fn: s => { s.tint += 30 } },
  '┃': { nm: 'gate', ring: 2, fn: s => { s.depth = Math.min(12, s.depth + 1) } },
  '♡': { nm: 'heart', ring: 3, fn: s => { s.emo = 'love' } },
  '△': { nm: 'think', ring: 4, fn: s => { s.primary = 'shield' } },
  '◐': { nm: 'self', ring: 5, fn: s => { s.dens = Math.min(3, s.dens + .5) } },
  '◯': { nm: 'witness', ring: 6, fn: s => { s.primary = 'bloomqr' } },
  '火': { nm: 'fire', fn: s => { s.tint += 330; s.dens = Math.min(3, s.dens + .3) } },
  '水': { nm: 'water', fn: s => { s.tint += 210; s.depth = Math.max(1, s.depth - 1) } },
  '空': { nm: 'sky', fn: s => { s.depth = Math.min(12, s.depth + 2) } },
  '雷': { nm: 'thunder', fn: s => { s.dens = Math.min(3, s.dens + 1) } },
  '響': { nm: 'echo', fn: s => { s.tint += 60 } },
  '華': { nm: 'bloom', fn: s => { s.emo = 'bloom' } },
  '輪': { nm: 'wheel', fn: s => { s.primary = 'mahoraga' } },
  '工': { nm: 'craft', fn: s => { s.primary = 'factory' } },
  '数': { nm: 'number', fn: s => { s.depth = 7 } },
  '影': { nm: 'shadow', fn: s => { s.tint += 180; s.dens = Math.max(.3, s.dens - .3) } }
}

export function applyGlyphs(text, state) {
  let fired = []
  for (const ch of text) {
    if (KOTO[ch]) { KOTO[ch].fn(state); fired.push(ch) }
  }
  return fired
}
