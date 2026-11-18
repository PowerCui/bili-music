(function () {
  'use strict';

  var MI = {
    PLAYBACK_PLAYING: 1,
    PLAYBACK_PAUSED: 2,
    PLAYBACK_STOPPED: 3,
    playback: { PLAYING: 1, PAUSED: 2, STOPPED: 3 },
  };
  window.wallpaperMediaIntegration = MI;

  var S = {
    title: '',
    artist: '',
    albumTitle: '',
    subTitle: '',
    genres: '',
    contentType: 'music',
    thumbnail: '',
    position: 0,
    duration: 0,
    state: MI.PLAYBACK_STOPPED,
  };

  var CHANNELS = ['Properties', 'Thumbnail', 'Playback', 'Timeline', 'Status'];
  var subs = { Properties: [], Thumbnail: [], Playback: [], Timeline: [], Status: [] };

  function snapArgs(name) {
    if (name === 'Properties') {
      return [
        {
          title: S.title,
          artist: S.artist,
          albumTitle: S.albumTitle,
          subTitle: S.subTitle,
          genres: S.genres,
          contentType: S.contentType,
        },
      ];
    }
    if (name === 'Thumbnail') {
      return [{ thumbnail: S.thumbnail }];
    }
    if (name === 'Playback') {
      return [{ state: S.state }];
    }
    if (name === 'Timeline') {
      return [
        {
          position: Math.max(0, Math.round(S.position)),
          duration: Math.max(0, Math.round(S.duration)),
        },
      ];
    }
    return [{ enabled: true }];
  }

  function dispatch(name) {
    var args = snapArgs(name);
    var list = subs[name];
    for (var i = 0; i < list.length; i++) {
      try {
        list[i].apply(window, args);
      } catch (e) {}
    }
  }

  function makeRegister(name) {
    return function (cb) {
      if (typeof cb !== 'function') return;
      if (subs[name].indexOf(cb) < 0) subs[name].push(cb);
      var replay = function () {
        try {
          cb.apply(window, snapArgs(name));
        } catch (e) {}
      };
      setTimeout(replay, 0);
    };
  }

  window.wallpaperRegisterMediaPropertiesListener = makeRegister('Properties');
  window.wallpaperRegisterMediaThumbnailListener = makeRegister('Thumbnail');
  window.wallpaperRegisterMediaPlaybackListener = makeRegister('Playback');
  window.wallpaperRegisterMediaTimelineListener = makeRegister('Timeline');
  window.wallpaperRegisterMediaStatusListener = makeRegister('Status');

  var audioSubs = [];
  var audioTimer = null;
  var spectrum = new Array(128);
  for (var ai = 0; ai < 128; ai++) spectrum[ai] = 0;

  function tickAudio() {
    var t = performance.now() / 1000;
    var playing = S.state === MI.PLAYBACK_PLAYING;
    for (var i = 0; i < 128; i++) {
      var band = i % 64;
      var falloff = Math.pow(1 - band / 64, 0.85);
      var wave = (Math.sin(t * 2.1 + band * 0.33) * 0.5 + 0.5) * 0.6;
      var jitter = Math.random() * 0.18;
      var beat = 0.3 * Math.pow(Math.max(0, Math.sin(t * 2.1)), 6);
      var v = playing ? (wave + jitter + beat) * falloff * 0.9 : 0;
      spectrum[i] = v < 0 ? 0 : v > 1 ? 1 : v;
    }
    dispatchAudio();
  }

  function dispatchAudio() {
    var snap = spectrum.slice(0);
    for (var i = 0; i < audioSubs.length; i++) {
      try {
        audioSubs[i](snap);
      } catch (e) {}
    }
  }

  function syncAudioTimer() {
    var want = S.state === MI.PLAYBACK_PLAYING && audioSubs.length > 0;
    if (want && audioTimer === null) {
      audioTimer = setInterval(tickAudio, 40);
    } else if (!want && audioTimer !== null) {
      clearInterval(audioTimer);
      audioTimer = null;
      for (var i = 0; i < 128; i++) spectrum[i] = 0;
      dispatchAudio();
    }
  }

  window.wallpaperRegisterAudioListener = function (cb) {
    if (typeof cb !== 'function') return;
    if (audioSubs.indexOf(cb) < 0) audioSubs.push(cb);
    setTimeout(function () {
      try {
        cb(spectrum.slice(0));
      } catch (e) {}
    }, 0);
    syncAudioTimer();
  };

  var defaults = null;

  function loadDefaults() {
    try {
      fetch(new URL('project.json', location.href))
        .then(function (r) {
          return r.ok ? r.json() : null;
        })
        .then(function (j) {
          if (!j) return;
          var p = (j.general && j.general.properties) || j.properties || null;
          if (!p) return;
          var out = {};
          for (var k in p) {
            if (!Object.prototype.hasOwnProperty.call(p, k)) continue;
            var v = p[k];
            if (v && typeof v === 'object' && ('value' in v || 'text' in v)) {
              out[k] = v.value !== undefined && v.value !== null ? v.value : v.text;
            } else {
              out[k] = v;
            }
          }
          defaults = out;
          deliverProps();
        })
        .catch(function () {});
    } catch (e) {}
  }

  function deliverProps() {
    if (!defaults) return;
    var pl = null;
    try {
      pl = window.wallpaperPropertyListener;
    } catch (e) {
      pl = null;
    }
    if (!pl || typeof pl.applyUserProperties !== 'function') return;
    var payload = {};
    for (var k in defaults) {
      if (!Object.prototype.hasOwnProperty.call(defaults, k)) continue;
      payload[k] = { value: defaults[k] };
    }
    try {
      pl.applyUserProperties(payload);
    } catch (e) {}
  }

  [700, 1600, 3200, 6000, 10000].forEach(function (ms) {
    setTimeout(function () {
      deliverProps();
      try {
        if (window.CD_NET && typeof window.CD_NET.setOffline === 'function') {
          window.CD_NET.setOffline(true);
        }
      } catch (e) {}
    }, ms);
  });

  var lyricsPending = null;
  var lyricsTimer = null;

  function tryPushLyrics() {
    if (!lyricsPending) return;
    var L = window.__lyrics;
    if (!L || typeof L.demo !== 'function') return;
    try {
      // 让壁纸自己的歌词引擎离线，别再去联网取词/覆盖我们推的歌词
      try {
        if (window.CD_NET && typeof window.CD_NET.setOffline === 'function') {
          window.CD_NET.setOffline(true);
        } else if (typeof L.offline === 'function') {
          L.offline(true);
        }
      } catch (e) {}
      var lrc = String(lyricsPending);
      var key = L.state && L.state.key ? String(L.state.key) : '';
      // 只有引擎算出曲目 key 后才落地：既写进它自己的本地缓存，
      // 这样它每 4s 的 sync() 命中缓存不会再清空/重取；再 demo 立刻渲染。
      if (!key) return;
      try {
        var pick = 'all';
        try {
          if (typeof L.info === 'function') {
            var inf = L.info() || {};
            if (inf.pick) pick = inf.pick;
          }
        } catch (e) {}
        var src = pick === 'all' ? 'local' : pick;
        localStorage.setItem(
          'cdly.' + key,
          JSON.stringify({ lrc: lrc, plain: '', none: false, src: src, at: Date.now() }),
        );
      } catch (e) {}
      L.demo(lrc);
      lyricsPending = null;
      if (lyricsTimer !== null) {
        clearInterval(lyricsTimer);
        lyricsTimer = null;
      }
    } catch (e) {}
  }

  function pushLyrics(lrc) {
    lyricsPending = lrc;
    tryPushLyrics();
    if (lyricsPending && lyricsTimer === null) {
      lyricsTimer = setInterval(tryPushLyrics, 800);
    }
  }

  function applyState(b) {
    if (!b || typeof b !== 'object') return;
    var meta =
      b.title !== undefined ||
      b.artist !== undefined ||
      b.albumTitle !== undefined ||
      b.subTitle !== undefined ||
      b.genres !== undefined ||
      b.contentType !== undefined;
    if (meta) {
      if (b.title !== undefined) S.title = String(b.title);
      if (b.artist !== undefined) S.artist = String(b.artist);
      if (b.albumTitle !== undefined) S.albumTitle = String(b.albumTitle);
      if (b.subTitle !== undefined) S.subTitle = String(b.subTitle);
      if (b.genres !== undefined) S.genres = String(b.genres);
      if (b.contentType !== undefined) S.contentType = String(b.contentType);
      dispatch('Properties');
    }
    if (b.thumbnail !== undefined && b.thumbnail !== S.thumbnail) {
      S.thumbnail = String(b.thumbnail);
      dispatch('Thumbnail');
    }
    if (b.state !== undefined && b.state !== S.state) {
      S.state = Number(b.state) || MI.PLAYBACK_STOPPED;
      dispatch('Playback');
      syncAudioTimer();
    }
    if (b.position !== undefined || b.duration !== undefined) {
      if (b.position !== undefined) S.position = Number(b.position) || 0;
      if (b.duration !== undefined) S.duration = Number(b.duration) || 0;
      dispatch('Timeline');
    }
    if (typeof b.lyrics === 'string' && b.lyrics.length > 0) {
      pushLyrics(b.lyrics);
    }
  }

  function onHostMessage(ev) {
    var m = ev && ev.data;
    if (typeof m === 'string') {
      try {
        m = JSON.parse(m);
      } catch (e) {
        return;
      }
    }
    if (!m || typeof m !== 'object') return;
    if (m.topic === 'state') {
      applyState(m.body);
    }
  }

  loadDefaults();

  function boot() {
    var wv = window.chrome && window.chrome.webview;
    if (wv && typeof wv.addEventListener === 'function') {
      wv.addEventListener('message', onHostMessage);
      try {
        wv.postMessage({ topic: 'ready' });
      } catch (e) {}
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      setTimeout(boot, 200);
    });
  } else {
    setTimeout(boot, 200);
  }
})();
