// Κ.BLOOM — fold/unfold/phi/wound/kappa from konomigami
import { P, PHI, K_STAR } from './constants.js'

export const BL = {
  fold: b => { let f = 1; b.forEach((e, k) => f *= Math.pow(P[k], Math.round(e))); return f },
  unfold: n => P.map(p => { let e = 0; while (n % p === 0) { n /= p; e++ } return e }),
  phi: b => { let s = 0; for (let k = 0; k < 6; k++) s += Math.max(0, 1 - Math.abs((b[k + 1] / Math.max(1, b[k])) - PHI)); return s / 6 },
  wound: (b, t = 4) => { let w = 1; b.forEach((e, k) => { if (e < t) w *= Math.pow(P[k], t - e) }); return w },
  kappa: a => a.b * 1.6 - a.h * .7 + .25,
  escure: n => { let ok = true; P.forEach((p, i) => { const m = (1 << P[i]) - 1; if (n % m === 0) ok = false }); return { ok } }
}
