// Κ.ORBS — Three.js 9-orb body with 7 rings each + buses
import { RCOL, TAU } from './constants.js'

const ORB_DEFS = [
  { id: 'head', lv: 5, pos: [0, 2.4, 0], r: .38 },
  { id: 'leye', lv: 6, pos: [-.5, 2.6, .3], r: .18 },
  { id: 'reye', lv: 6, pos: [.5, 2.6, .3], r: .18 },
  { id: 'lchest', lv: 4, pos: [-.7, 1.4, 0], r: .32 },
  { id: 'core', lv: 2, pos: [0, 1.2, 0], r: .28 },
  { id: 'rchest', lv: 3, pos: [.7, 1.4, 0], r: .32 },
  { id: 'lhip', lv: 1, pos: [-.55, .2, 0], r: .22 },
  { id: 'base', lv: 0, pos: [0, -.1, 0], r: .26 },
  { id: 'rhip', lv: 1, pos: [.55, .2, 0], r: .22 }
]

const BUS_DEFS = [
  { f: 'head', t: 'lchest', c: 0xdc143c }, { f: 'lchest', t: 'core', c: 0xdc143c },
  { f: 'core', t: 'base', c: 0xdc143c }, { f: 'base', t: 'core', c: 0xff4444 },
  { f: 'core', t: 'lchest', c: 0xff4444 }, { f: 'lchest', t: 'head', c: 0xff4444 },
  { f: 'head', t: 'leye', c: 0x00aaff }, { f: 'head', t: 'reye', c: 0x00aaff },
  { f: 'core', t: 'rchest', c: 0x9944ff }, { f: 'core', t: 'lhip', c: 0x9944ff },
  { f: 'core', t: 'rhip', c: 0x9944ff }, { f: 'rchest', t: 'base', c: 0xff8800 }
]

const GA = [
  { x: Math.PI / 2, y: 0, z: 0 }, { x: 0, y: 0, z: 0 },
  { x: Math.PI / 2, y: Math.PI / 2, z: 0 }, { x: Math.PI / 4, y: Math.PI / 4, z: 0 },
  { x: Math.PI / 2, y: 0, z: Math.PI / 4 }, { x: Math.PI / 3, y: -Math.PI / 3, z: Math.PI / 6 },
  { x: 0, y: Math.PI / 4, z: Math.PI / 2 }
]

export function buildOrbs(scene, THREE) {
  const orbs = {}
  ORB_DEFS.forEach(def => {
    const g = new THREE.Group(); g.position.set(...def.pos)
    const core = new THREE.Mesh(new THREE.SphereGeometry(def.r * .6, 24, 24),
      new THREE.MeshPhongMaterial({ color: RCOL[def.lv], emissive: RCOL[def.lv], emissiveIntensity: .15, transparent: true, opacity: .6 }))
    g.add(core)
    g.add(new THREE.Mesh(new THREE.IcosahedronGeometry(def.r * .85, 1),
      new THREE.MeshBasicMaterial({ color: RCOL[def.lv], wireframe: true, transparent: true, opacity: .06 })))
    const rings = []
    for (let ri = 0; ri < 7; ri++) {
      const rr = def.r * (.5 + ri * .12), rg = new THREE.Group()
      const mat = new THREE.MeshBasicMaterial({ color: RCOL[ri], transparent: true, opacity: ri === def.lv ? .5 : .1 })
      rg.add(new THREE.Mesh(new THREE.TorusGeometry(rr, .012, 8, 48), mat))
      for (let n = 0; n < 3 + ri; n++) {
        const ang = n / (3 + ri) * TAU
        const nm = new THREE.Mesh(new THREE.SphereGeometry(.015, 4, 4),
          new THREE.MeshBasicMaterial({ color: RCOL[ri], transparent: true, opacity: ri === def.lv ? .7 : .15 }))
        nm.position.set(Math.cos(ang) * rr, Math.sin(ang) * rr, 0); rg.add(nm)
      }
      const ga = GA[ri]; rg.rotation.set(ga.x, ga.y, ga.z); g.add(rg)
      rings.push({ mesh: rg, mat, energy: 0, base: ri === def.lv ? .5 : .1, ring: ri })
    }
    scene.add(g)
    orbs[def.id] = { group: g, core, rings, pulse: 0, activity: 0, def }
  })
  return orbs
}

export function buildBuses(scene, THREE) {
  const buses = []
  BUS_DEFS.forEach(b => {
    const p1 = new THREE.Vector3(...ORB_DEFS.find(o => o.id === b.f).pos)
    const p2 = new THREE.Vector3(...ORB_DEFS.find(o => o.id === b.t).pos)
    const mid = new THREE.Vector3().addVectors(p1, p2).multiplyScalar(.5)
    mid.z += .4; mid.x += (Math.random() - .5) * .3
    const curve = new THREE.QuadraticBezierCurve3(p1, mid, p2)
    const geo = new THREE.BufferGeometry().setFromPoints(curve.getPoints(30))
    const mat = new THREE.LineBasicMaterial({ color: b.c, transparent: true, opacity: .08 })
    const line = new THREE.Line(geo, mat); scene.add(line)
    const dot = new THREE.Mesh(new THREE.SphereGeometry(.02, 4, 4),
      new THREE.MeshBasicMaterial({ color: b.c, transparent: true, opacity: .3 }))
    scene.add(dot)
    buses.push({ line, mat, curve, dot, progress: Math.random() })
  })
  return buses
}

export function buildStars(scene, THREE) {
  const geo = new THREE.BufferGeometry(), pos = new Float32Array(1500 * 3)
  for (let i = 0; i < 4500; i++) pos[i] = (Math.random() - .5) * 40
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3))
  scene.add(new THREE.Points(geo, new THREE.PointsMaterial({ color: 0xffffff, size: .02, transparent: true, opacity: .3 })))
}

export const RECURSIONS = [
  { d: 0, ring: 0, orb: 'base', lbl: 'GUT' }, { d: 1, ring: 1, orb: 'lhip', lbl: 'SENSE' },
  { d: 2, ring: 2, orb: 'core', lbl: 'GATE' }, { d: 3, ring: 3, orb: 'rchest', lbl: 'AFFECT' },
  { d: 4, ring: 4, orb: 'lchest', lbl: 'THINK' }, { d: 5, ring: 5, orb: 'head', lbl: 'SELF' },
  { d: 6, ring: 6, orb: 'leye', lbl: 'OBSERVE' },
  { d: 7, ring: 0, orb: 'base', lbl: 'REFOLD' }, { d: 8, ring: 2, orb: 'core', lbl: 'BREATHE' },
  { d: 9, ring: 3, orb: 'rchest', lbl: 'RESONATE' }, { d: 10, ring: 4, orb: 'lchest', lbl: 'ASSEMBLE' },
  { d: 11, ring: 6, orb: 'reye', lbl: 'RELEASE' }
]

export { ORB_DEFS }
