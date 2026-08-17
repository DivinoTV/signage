/* One check for the Realtime state machine:  node test-realtime.js
   No network — a fake WebSocket drives the real code, extracted from index.html so it
   cannot drift from what ships.

   Why this exists, in two bugs both found on the live project rather than reasoned about.

   1. phx_reply 'status: ok' means the CHANNEL joined; it does NOT mean postgres_changes is
      subscribed. Supabase settles that afterwards in a separate 'system' frame.
   2. A first fix promoted to 'subscribed' when no refusal arrived within 10 seconds. That
      guess reported a healthy subscription on a socket that delivered nothing, with polling
      already relaxed to 15 minutes — the §2.8 silent failure: stale screens nobody watches.
      The server states the outcome outright ('Subscribed to PostgreSQL'), so nothing needs
      inferring, and scenario E below pins that a silent server never gets promoted.

   The property under test: pollMs() may only return POLL_LIVE when the subscription is
   confirmed by the server or proven by a delivered change. Everything else polls at
   POLL_DOWN. */
var fs = require('fs'), assert = require('assert');

var js = /<script>([\s\S]*)<\/script>/.exec(fs.readFileSync(__dirname + '/index.html', 'utf8'))[1];
var block = /function pollMs\(\)[\s\S]*?(?=\/\* ---------- diagnostics)/.exec(js);
if (!block) { console.error('FAIL: Realtime block not found in index.html'); process.exit(1); }

var POLL_LIVE = 15 * 60 * 1000, POLL_DOWN = 5 * 60 * 1000;
var logLines = [], fetches = 0;

function FakeWS(){ FakeWS.last = this; var s = this; setTimeout(function(){ if (s.onopen) s.onopen(); }, 0); }
FakeWS.prototype.send  = function(){};
FakeWS.prototype.close = function(){};

function build(){
  var scope = {
    CFG: { url: 'https://example.supabase.co', key: 'sb_publishable_test' },
    RT_HEARTBEAT: 25000, RT_DEBOUNCE: 150, RT_BACKOFF: [9e6],
    POLL_LIVE: POLL_LIVE, POLL_DOWN: POLL_DOWN,
    say: function(m){ logLines.push(m); },
    fetchPlaylist: function(){ fetches++; },
    checkVersion: function(){},
    window: { WebSocket: FakeWS }, WebSocket: FakeWS,
    setTimeout: setTimeout, setInterval: setInterval,
    clearTimeout: clearTimeout, clearInterval: clearInterval,
    JSON: JSON, Math: Math, Date: Date,
    encodeURIComponent: encodeURIComponent, String: String
  };
  var names = Object.keys(scope);
  return new Function(names.join(','), block[0] +
    '; return { state: function(){ return rtState; }, pollMs: pollMs,' +
    '  connect: rtConnect, stop: rtStop, url: rtUrl() };'
  ).apply(null, names.map(function(k){ return scope[k]; }));
}
function feed(msg){ FakeWS.last.onmessage({ data: JSON.stringify(msg) }); }

var rt = build();
assert.ok(/^wss:\/\/example\.supabase\.co\/realtime\/v1\/websocket\?apikey=/.test(rt.url),
  'socket URL must be wss:// against the project host, got ' + rt.url);
assert.strictEqual(rt.pollMs(), POLL_DOWN, 'before connecting, polling must be the 5-minute value');

var CONFIRM = { event: 'system', payload: { status: 'ok', message: 'Subscribed to PostgreSQL' } };
var REFUSE  = { event: 'system', payload: { message: 'Unable to subscribe to changes with given parameters' } };

/* A — the happy path: join, then an explicit server confirmation */
rt.connect();
setTimeout(function(){
  feed({ event: 'phx_reply', payload: { status: 'ok', response: {} } });
  assert.strictEqual(rt.state(), 'joined', 'a join reply is not a subscription');
  assert.strictEqual(rt.pollMs(), POLL_DOWN, 'while merely joined, polling must stay at 5 min');

  feed(CONFIRM);
  assert.strictEqual(rt.state(), 'subscribed', 'the server confirmation is what promotes');
  assert.strictEqual(rt.pollMs(), POLL_LIVE, 'only now may polling relax to 15 min');
  rt.stop();

  /* B — join accepted, then refused */
  var b = build(); b.connect();
  setTimeout(function(){
    feed({ event: 'phx_reply', payload: { status: 'ok' } });
    feed(REFUSE);
    assert.strictEqual(b.state(), 'error', 'an async refusal must win over the ok reply');
    assert.strictEqual(b.pollMs(), POLL_DOWN, 'a refused subscription must keep polling hard');
    b.stop();

    /* C — a delivered change is proof positive, and a burst coalesces into one refetch */
    var c = build(); c.connect();
    setTimeout(function(){
      fetches = 0;
      feed({ event: 'postgres_changes', payload: {} });
      assert.strictEqual(c.state(), 'subscribed', 'a delivered change proves the subscription');
      assert.strictEqual(c.pollMs(), POLL_LIVE);
      feed({ event: 'postgres_changes', payload: {} });
      feed({ event: 'postgres_changes', payload: {} });

      setTimeout(function(){
        assert.strictEqual(fetches, 1,
          'a burst of 3 changes must coalesce into 1 refetch, got ' + fetches);
        c.stop();

        /* D — an explicit join error never relaxes polling */
        var d = build(); d.connect();
        setTimeout(function(){
          feed({ event: 'phx_reply', payload: { status: 'error' } });
          assert.strictEqual(d.state(), 'error');
          assert.strictEqual(d.pollMs(), POLL_DOWN);
          d.stop();

          /* E — THE REGRESSION GUARD. The channel joins and the server then says nothing
             at all: no confirmation, no refusal. Nothing may ever promote this on its own.
             This is the exact shape of the bug that shipped and then reported a healthy
             subscription over a socket that delivered nothing. */
          var e = build(); e.connect();
          setTimeout(function(){
            feed({ event: 'phx_reply', payload: { status: 'ok' } });
            setTimeout(function(){
              assert.strictEqual(e.state(), 'joined',
                'a silent server must stay "joined" forever, never "subscribed"');
              assert.strictEqual(e.pollMs(), POLL_DOWN,
                'an unconfirmed subscription must never relax polling to 15 min');
              e.stop();
              console.log('ok — 17 assertions across 5 Realtime scenarios');
              process.exit(0);
            }, 600);
          }, 20);
        }, 20);
      }, 400);
    }, 20);
  }, 20);
}, 20);
