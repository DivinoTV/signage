/* One check, no framework:  node test-playlist.js
   Covers usable() — the filter that stands between a bad row and a blank guest-room
   screen (F3, F7, video-not-built, schedule windows). Pulls the real function out of
   index.html so it cannot drift from what ships. */
var fs = require('fs');
var src = fs.readFileSync(__dirname + '/index.html', 'utf8');
var m = /function usable\(rows\)\{[\s\S]*?\n\}/.exec(src);
if (!m) { console.error('FAIL: usable() not found in index.html'); process.exit(1); }

var say = function(){};                      /* stub the ring-buffer logger */
var usable = eval('(' + m[0] + ')');
var assert = require('assert');

var img = function(o){
  o = o || {};
  return {
    media_url: o.url || 'https://x/a.jpg',
    media_type: o.type || 'image',
    duration_seconds: 8,
    starts_at: o.starts || null,
    ends_at: o.ends || null
  };
};
var past   = new Date(Date.now() - 864e5).toISOString();
var future = new Date(Date.now() + 864e5).toISOString();

assert.strictEqual(usable([]), null, 'empty array must be rejected, not adopted');
assert.strictEqual(usable(null), null, 'null must be rejected');
assert.strictEqual(usable({}), null, 'non-array must be rejected');
assert.strictEqual(usable([{}]), null, 'row with no media_url must be rejected');
assert.strictEqual(usable([img({type:'video'})]), null, 'video-only playlist is not usable yet');
assert.strictEqual(usable([img({type:'audio'})]), null, 'unknown media_type must be dropped');

assert.strictEqual(usable([img()]).length, 1, 'a plain image row must survive');
assert.strictEqual(usable([img(), img({type:'video'})]).length, 1, 'video dropped, image kept');

assert.strictEqual(usable([img({starts:future})]), null, 'not-yet-started must be hidden');
assert.strictEqual(usable([img({ends:past})]), null, 'expired must be hidden');
assert.strictEqual(usable([img({starts:past, ends:future})]).length, 1, 'live window must show');
assert.strictEqual(usable([img({starts:'not-a-date'})]).length, 1, 'unparseable bound must not hide the slide');

/* §2.7 shape validation — the injection guard. F7 and F13. */
var SLUG = eval(/var SLUG\s*=\s*(\/.*?\/);/.exec(src)[1]);
var slug = eval('(' + /function slug\(v\)\{[^\n]*\}/.exec(src)[0] + ')');

assert.strictEqual(slug('deluxe'), 'deluxe', 'a real slug passes');
assert.strictEqual(slug('junior-suit'), 'junior-suit', 'F7: a typo passes shape and matches no rows');
assert.strictEqual(slug('a,zone.neq.x'), null, 'F13: filter syntax must be rejected');
assert.strictEqual(slug('a)or(1.eq.1'), null, 'parens must be rejected');
assert.strictEqual(slug('Deluxe'), null, 'uppercase must be rejected');
assert.strictEqual(slug('a b'), null, 'spaces must be rejected');
assert.strictEqual(slug('*'), null, 'wildcard must be rejected');
assert.strictEqual(slug(''), null, 'empty must be rejected');
assert.strictEqual(slug(null), null, 'missing must be rejected');
assert.strictEqual(slug(new Array(35).join('a')), null, 'over 32 chars must be rejected');

/* Fallback filenames must match what the TV actually asks for. A rename here fails
   silently in production: the TV just falls through to a dark screen, and nobody in a
   guest room reports a slide they never knew existed. Properties with no artwork yet are
   fine — falling through is the design. Wrong-NAMED artwork is not. */
var fmt = /var FALLBACK_FMT\s*=\s*'([^']+)'/.exec(src)[1];
var shared = /var FALLBACK\s*=\s*'([^']+)'/.exec(src)[1];
var pattern = new RegExp('^' + fmt.split('/').pop().replace('%', '([a-z0-9-]{1,32})') + '$');
var sharedName = shared.split('/').pop();

var dir = __dirname + '/fallback';
var files = fs.existsSync(dir) ? fs.readdirSync(dir).filter(function(f){ return !/^\./.test(f); }) : [];
files.forEach(function(f){
  assert.ok(f === sharedName || pattern.test(f),
    'fallback/' + f + ' matches neither "' + sharedName + '" nor "' + fmt.split('/').pop() +
    '" — the TV will never request it');
});
console.log('ok — 22 assertions + ' + files.length + ' fallback file(s) named correctly' +
  (files.length ? ' (' + files.join(', ') + ')' : ''));
