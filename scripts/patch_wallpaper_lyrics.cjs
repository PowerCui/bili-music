// Patches the workshop wallpaper's lyrics.js so the host app can own the
// lyric source ("external lyric lock"), preventing the wallpaper's own
// lyric engine (which re-syncs every 4s and fetches from its own sources)
// from overwriting the lyrics pushed by the host app.
//
// Runs in CI right after the wallpaper assets zip is extracted.
const fs = require('fs');
const path = require('path');

const file = path.join(process.cwd(), 'assets', 'wallpaper', 'lyrics.js');
let s = fs.readFileSync(file, 'utf8');

if (s.indexOf('__extLock') >= 0) {
  console.log('[patch] lyrics.js already patched');
  process.exit(0);
}

let changed = false;

// 1) Make sync() honor the external lock: never auto-load / wipe while locked.
const syncPairs = [
  [
    'function sync(keepPos, noCache) {\n    if (!box || !on) return;',
    'function sync(keepPos, noCache) {\n    if (!box || !on) return;\n    if (S.ext) return; /* __extLock */',
  ],
  [
    'function sync(keepPos, noCache) {\r\n    if (!box || !on) return;',
    'function sync(keepPos, noCache) {\r\n    if (!box || !on) return;\r\n    if (S.ext) return; /* __extLock */',
  ],
];
for (const [a, b] of syncPairs) {
  if (s.indexOf(a) >= 0) {
    s = s.replace(a, b);
    changed = true;
    break;
  }
}

// 2) Expose ext(lrc) / extClear() on the public API object (right after demo).
const demoAnchor =
  "demo: function (lrc) { apply({ lrc: lrc }, track() || { title: 'demo' }, S.key); },";
if (s.indexOf(demoAnchor) >= 0) {
  const inject =
    demoAnchor +
    "\n      ext: function (lrc) { S.ext = true; try { if (box) { box.classList.remove('is-idle'); box.classList.remove('is-empty'); } } catch (e) {} apply({ lrc: lrc }, track() || { title: 'external' }, S.key); }," +
    '\n      extClear: function () { S.ext = false; },';
  s = s.replace(demoAnchor, inject);
  changed = true;
}

if (!changed) {
  console.error('[patch] anchors not found; lyrics.js NOT patched');
  process.exit(1);
}

fs.writeFileSync(file, s, 'utf8');
console.log('[patch] lyrics.js patched (external lyric lock)');
