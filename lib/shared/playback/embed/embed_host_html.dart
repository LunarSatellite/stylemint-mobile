import 'dart:convert';

import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_warmup.dart';

/// Builds the page an embed slot's WebView loads. [origin] is the origin the
/// platform players are told they are embedded on.
///
/// The page only drives each platform's official player API: the YouTube
/// IFrame Player API, TikTok's Embed Player over postMessage, and the Facebook
/// Embedded Video Player. It never styles, hides or scripts inside a
/// platform's player; YouTube's developer policies forbid that. Besides that
/// it only adds resource hints that open connections to TikTok's player hosts
/// ([EmbedWarmup]) ahead of a TikTok reel.
///
/// Dart talks to the page through `window.smPlayer`; the page reports back
/// through the `sm` JavaScript handler with `{token, type, ...}` events.
String embedHostHtml({required String origin}) => _template
    .replaceFirst('__ORIGIN__', jsonEncode(origin))
    .replaceFirst('__TT_WARM__', jsonEncode(EmbedWarmup.tikTokOrigins));

const _template = r'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<link rel="icon" href="data:,">
<style>
html,body{margin:0;padding:0;width:100%;height:100%;background:#000;overflow:hidden}
#stage{position:fixed;left:0;top:0;right:0;bottom:0;display:flex;align-items:center;justify-content:center}
#stage>iframe{border:0;width:100%;height:100%;display:block}
</style>
</head>
<body>
<div id="stage"></div>
<script>
(function () {
  'use strict';
  var ORIGIN = __ORIGIN__;
  var TT_WARM = __TT_WARM__;
  var WARM_MS = 10000;
  var stage = document.getElementById('stage');
  var cur = blank(0);
  var bridgeReady = !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler);
  var outbox = [];

  function blank(token) {
    return {token: token, platform: null, id: null, href: null, wantPlay: false,
            muted: false, durationSent: false, fbStarted: false,
            preroll: false, prerolled: false, refusedMuted: false, progressed: false,
            held: false};
  }

  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    bridgeReady = true;
    var queued = outbox;
    outbox = [];
    for (var i = 0; i < queued.length; i++) window.flutter_inappwebview.callHandler('sm', queued[i]);
  });

  function emit(type, extra, token) {
    var message = {token: token === undefined ? cur.token : token, type: type};
    if (extra) for (var key in extra) message[key] = extra[key];
    if (bridgeReady) window.flutter_inappwebview.callHandler('sm', message);
    else outbox.push(message);
  }

  function emitDuration(seconds) {
    if (cur.durationSent || !(seconds > 0)) return;
    cur.durationSent = true;
    emit('duration', {seconds: Math.round(seconds)});
  }

  // ---- Connection warm-up: resource hints to official player hosts only. ----
  var warmedAt = {};

  function warm(origins) {
    if (!origins || !origins.length || !document.head) return;
    var now = Date.now();
    var hints = ['dns-prefetch', 'preconnect'];
    for (var i = 0; i < origins.length; i++) {
      var origin = origins[i];
      if (typeof origin !== 'string' || !/^https:\/\/[a-z0-9.-]+$/i.test(origin)) continue;
      if (warmedAt[origin] && now - warmedAt[origin] < WARM_MS) continue;
      warmedAt[origin] = now;
      for (var j = 0; j < hints.length; j++) {
        // Re-inserted, because a hint only acts when it enters the document.
        var id = 'warm-' + hints[j] + '-' + origin;
        var old = document.getElementById(id);
        if (old && old.parentNode) old.parentNode.removeChild(old);
        var link = document.createElement('link');
        link.id = id;
        link.rel = hints[j];
        link.href = origin;
        document.head.appendChild(link);
      }
    }
  }

  // ---- YouTube: IFrame Player API. One player per slot, reused per reel. ----
  var yt = null, ytReady = false, ytVideoId = null, ytApiRequested = false, ytWaiters = [];
  var YT_STATES = {'0': 'ended', '1': 'playing', '2': 'paused', '3': 'buffering', '5': 'cued'};

  function withYouTube(callback) {
    if (window.YT && window.YT.Player) { callback(); return; }
    ytWaiters.push(callback);
    if (ytApiRequested) return;
    ytApiRequested = true;
    var script = document.createElement('script');
    script.src = 'https://www.youtube.com/iframe_api';
    script.onerror = function () {
      ytApiRequested = false;
      ytWaiters = [];
      emit('error', {code: 'yt_api_load_failed'});
    };
    document.head.appendChild(script);
  }

  window.onYouTubeIframeAPIReady = function () {
    var waiters = ytWaiters;
    ytWaiters = [];
    for (var i = 0; i < waiters.length; i++) waiters[i]();
  };

  function ytApply() {
    // Sound only while the reel is on screen; a pre-rolling reel stays muted.
    if (cur.muted || !cur.wantPlay) yt.mute(); else yt.unMute();
    if (ytVideoId !== cur.id) {
      ytVideoId = cur.id;
      if (cur.wantPlay || cur.preroll) yt.loadVideoById(cur.id); else yt.cueVideoById(cur.id);
    } else if (cur.wantPlay || (cur.preroll && !cur.prerolled)) {
      yt.playVideo();
    } else {
      emit('cued');
    }
  }

  // The viewer paused the reel on screen. A paused YouTube player shows its
  // own suggestions panel, which nobody can tap here (the page never takes
  // touches). Cue the video again at the current time instead: a cued player
  // shows the video's thumbnail, and playVideo() starts from startSeconds
  // (IFrame Player API, cueVideoById).
  function ytHold() {
    var at = 0;
    try { at = yt.getCurrentTime() || 0; } catch (e) {}
    cur.held = true;
    yt.cueVideoById({videoId: cur.id, startSeconds: at});
  }

  function ytAssign() {
    var token = cur.token;
    withYouTube(function () {
      if (token !== cur.token) return;
      if (yt) { if (ytReady) ytApply(); return; }
      var host = document.createElement('div');
      host.id = 'ytp';
      stage.appendChild(host);
      ytVideoId = cur.id;
      yt = new YT.Player('ytp', {
        width: '100%',
        height: '100%',
        videoId: cur.id,
        playerVars: {
          playsinline: 1, controls: 0, rel: 0, iv_load_policy: 3, fs: 0,
          disablekb: 1, enablejsapi: 1, autoplay: 0,
          origin: ORIGIN, widget_referrer: ORIGIN
        },
        events: {
          onReady: function () { ytReady = true; emit('ready'); ytApply(); },
          onStateChange: function (event) {
            // A cue reported while asked to play is not this reel's state: the
            // viewer resumed before a hold's cue landed (so play again, in
            // case the cue came last), or it is left over from the reel this
            // player held before.
            if (event.data === 5 && cur.wantPlay) { if (cur.held) yt.playVideo(); return; }
            var state = YT_STATES[String(event.data)];
            if (state) emit(state);
            if (event.data === 1) emitDuration(yt.getDuration());
            if (event.data === 1 && cur.wantPlay) cur.held = false;
            // Reels loop. Replay on end rather than the loop playerVar, which
            // needs a playlist and re-buffers from the network each pass.
            if (event.data === 0 && cur.wantPlay) { yt.seekTo(0, true); yt.playVideo(); }
            // A pre-rolling reel holds its first moving frames until it is on
            // screen, so a swipe to it shows video at once. A held reel stays
            // cued: pausing it would bring the suggestions panel back.
            if (event.data === 1 && !cur.wantPlay) { if (!cur.held) { cur.prerolled = true; yt.pauseVideo(); } }
          },
          onError: function (event) { emit('error', {code: 'yt_' + event.data}); },
          onAutoplayBlocked: function () {
            cur.muted = true;
            emit('autoplayBlocked');
            yt.mute();
            if (cur.wantPlay) yt.playVideo();
          }
        }
      });
    });
  }

  // ---- TikTok: Embed Player v1, controlled over postMessage. ----
  // One player per reel. A slot asked again for the reel it already holds
  // keeps that player (see smPlayer.assign), so a pre-loaded reel starts from
  // the page, scripts and video it has already fetched.
  //
  // Playback always starts muted, in one step (mute + play): TikTok refuses
  // to start with sound (error 3002) and waiting for that refusal costs a
  // round trip. Sound is asked for once frames are moving. TikTok's muted
  // URL parameter is not used: it would stop the sound being turned on at
  // all. A reel already on screen when its player is created also autoplays,
  // a second chance should a play message be lost; a pre-loaded one does not.
  var tt = null, ttId = null, ttReady = false, ttPlaying = false, ttStarted = false, ttFailed = false;
  var ttSound = false, ttSoundOk = false, ttTime = null, ttTimeSeen = false;
  var ttSoundTimer = null;

  // How long to wait for TikTok to answer an unMute before treating silence
  // as a refusal. Long enough for a round trip on a slow connection, short
  // enough that a reel does not play most of its length in silence.
  var TT_SOUND_TIMEOUT = 1500;
  var TT_STATES = {'-1': 'init', '0': 'ended', '1': 'playing', '2': 'paused', '3': 'buffering'};

  function ttSend(type, value) {
    if (!tt || !tt.contentWindow) return;
    var message = {'x-tiktok-player': true, type: type};
    if (value !== undefined) message.value = value;
    tt.contentWindow.postMessage(message, '*');
  }

  // Whether this slot's player already holds TikTok reel [id], loaded and
  // healthy, so it can be re-activated without a new iframe.
  function ttKeeps(id) {
    return !!tt && ttReady && !ttFailed && ttId === id;
  }

  function ttStartMuted() {
    ttSound = false;
    ttSend('mute');
    ttSend('play');
  }

  function ttClearSoundTimer() {
    if (ttSoundTimer !== null) { clearTimeout(ttSoundTimer); ttSoundTimer = null; }
  }

  function ttAskSound() {
    if (cur.muted || !cur.wantPlay || ttSound) return;
    ttSound = true;
    ttSend('unMute');
    // TikTok answers an unMute one of three ways: onMute{value:false},
    // error 3002, or a pause. It can also answer none of them, and there was
    // nothing watching for that: ttSound stayed true, no refusal was ever
    // reported, so Dart never learned the reel was silent and the "Turn
    // sound on" button -- which only appears once a refusal is known --
    // never rendered. The reel played its whole length in silence with no
    // way for the viewer to do anything about it.
    //
    // Treat silence as a refusal. That mutes cleanly and surfaces the
    // button, so sound is one tap away, and that tap is a real user gesture,
    // which is what the platform wanted in the first place.
    ttClearSoundTimer();
    ttSoundTimer = setTimeout(function () {
      ttSoundTimer = null;
      if (ttSound && !ttSoundOk && cur.platform === 'tiktok') ttSoundRefused();
    }, TT_SOUND_TIMEOUT);
  }

  // The frames are moving for the reel on screen: tell Dart once, then ask
  // for sound.
  function ttProgress() {
    if (!cur.progressed) { cur.progressed = true; emit('progress'); }
    ttAskSound();
  }

  // TikTok would not play with sound: carry on muted at once, in one step.
  // A refusal while already muted is retried only once per reel.
  function ttSoundRefused() {
    ttClearSoundTimer();
    var retry = ttSound || !cur.refusedMuted;
    if (!ttSound) cur.refusedMuted = true;
    cur.muted = true;
    ttSound = false;
    ttSoundOk = false;
    emit('autoplayBlocked');
    ttSend('mute');
    if (cur.wantPlay && retry) ttSend('play');
  }

  function ttApply() {
    if (!tt || !ttReady) return; // onPlayerReady applies the latest request.
    if (cur.wantPlay) {
      if (ttPlaying) ttAskSound();
      else if (ttSoundOk && !cur.muted) ttSend('play');
      else ttStartMuted();
    } else if (cur.preroll && !ttStarted) {
      // Pre-roll: fetch and decode the first frames muted, then hold them.
      ttStartMuted();
    } else {
      ttSend('pause');
    }
  }

  // Dart saw no moving frames soon after asking for them: start again muted.
  // Sound follows the next sign of moving frames. A player that says it is
  // playing but has never reported its time gives no better sign than that.
  function ttRetryStart() {
    if (!tt || !ttReady || !cur.wantPlay || cur.progressed) return;
    if (ttPlaying && !ttTimeSeen) { ttProgress(); return; }
    ttStartMuted();
  }

  function ttAssign() {
    warm(TT_WARM);
    var frame = document.createElement('iframe');
    frame.src = 'https://www.tiktok.com/player/v1/' + encodeURIComponent(cur.id) +
      '?controls=0&progress_bar=0&play_button=0&volume_control=0&fullscreen_button=0' +
      '&timestamp=0&music_info=0&description=0&rel=0&native_context_menu=0' +
      '&closed_caption=0&loop=1&autoplay=' + (cur.wantPlay ? 1 : 0);
    frame.setAttribute('allow', 'autoplay; encrypted-media; fullscreen');
    stage.appendChild(frame);
    tt = frame;
    ttId = cur.id;
    ttClearSoundTimer();
    ttReady = false; ttPlaying = false; ttStarted = false; ttFailed = false;
    ttSound = false; ttSoundOk = false; ttTime = null;
  }

  // Re-activates the player this slot already holds for the current reel.
  function ttReuse() {
    emit('ready');
    if (ttPlaying && cur.wantPlay) emit('playing');
    ttApply();
    if (!cur.wantPlay && !(cur.preroll && !ttStarted)) emit('cued');
  }

  window.addEventListener('message', function (event) {
    if (cur.platform !== 'tiktok' || !tt || event.source !== tt.contentWindow) return;
    var data = event.data;
    if (typeof data === 'string') { try { data = JSON.parse(data); } catch (e) { return; } }
    if (!data || !data['x-tiktok-player']) return;
    switch (data.type) {
      case 'onPlayerReady':
        ttReady = true;
        emit('ready');
        if (cur.wantPlay || (cur.preroll && !ttStarted)) ttApply(); else emit('cued');
        break;
      case 'onStateChange':
        ttPlaying = data.value === 1;
        if (data.value === 1) {
          ttStarted = true;
          if (!cur.wantPlay) {
            // Off screen: hold the first frames of a pre-roll, or stay still.
            // Dart is not told the reel played, so its poster stays up.
            ttSend('pause');
            if (cur.preroll && !cur.prerolled) { cur.prerolled = true; emit('prerolled'); }
            break;
          }
          emit('playing');
          ttAskSound();
          break;
        }
        // Paused right after asking for sound: the sound was refused.
        if (data.value === 2 && cur.wantPlay && ttSound && !ttSoundOk) { ttSoundRefused(); break; }
        // -1 (init) and 3 (buffering) are still loading: the poster stays.
        var state = TT_STATES[String(data.value)];
        if (state) emit(state);
        break;
      case 'onCurrentTime':
        var time = data.value || {};
        if (time.duration) emitDuration(time.duration);
        if (typeof time.currentTime === 'number') {
          ttTimeSeen = true;
          var advanced = ttTime !== null && time.currentTime > ttTime;
          ttTime = time.currentTime;
          if (advanced && cur.wantPlay) ttProgress();
        }
        break;
      case 'onMute':
        // Only this page changes the player's sound (the viewer cannot reach
        // its controls), so this confirms a request rather than reporting one.
        if (!data.value && ttSound) { ttSoundOk = true; ttClearSoundTimer(); }
        break;
      case 'onPlayerError':
        var code = data.value && data.value.errorCode;
        if (code === 3002) { ttSoundRefused(); break; }
        // 1001 invalid video, 2001 server error, 3001 playback error: this
        // player is finished. Dart shows the poster with its can't-play note,
        // after one retry with a new player for 2001 and 3001.
        ttFailed = true;
        emit('error', {code: 'tt_' + code});
        break;
    }
  });

  // ---- Facebook: Embedded Video Player through the JS SDK. ----
  var fbRequested = false, fbInitialized = false, fbWaiters = [], fbPlayer = null, fbWatchdog = null;

  function withFacebook(callback) {
    if (fbInitialized) { callback(); return; }
    fbWaiters.push(callback);
    if (fbRequested) return;
    fbRequested = true;
    window.fbAsyncInit = function () {
      FB.init({xfbml: false, version: 'v21.0'});
      FB.Event.subscribe('xfbml.ready', onFacebookReady);
      fbInitialized = true;
      var waiters = fbWaiters;
      fbWaiters = [];
      for (var i = 0; i < waiters.length; i++) waiters[i]();
    };
    var script = document.createElement('script');
    script.src = 'https://connect.facebook.net/en_US/sdk.js';
    script.async = true;
    script.onerror = function () {
      fbRequested = false;
      fbWaiters = [];
      emit('error', {code: 'fb_sdk_load_failed'});
    };
    document.head.appendChild(script);
  }

  // The Facebook player has no autoplay-blocked event. If sound-on playback
  // has not started soon after play(), retry muted as YouTube and TikTok do.
  function armFacebookWatchdog() {
    clearTimeout(fbWatchdog);
    var token = cur.token;
    fbWatchdog = setTimeout(function () {
      if (token !== cur.token || !fbPlayer || !cur.wantPlay || cur.fbStarted || cur.muted) return;
      cur.muted = true;
      emit('autoplayBlocked');
      fbPlayer.mute();
      fbPlayer.play();
    }, 3000);
  }

  function fbApply() {
    if (!fbPlayer) return;
    if (cur.muted) fbPlayer.mute(); else fbPlayer.unmute();
    if (cur.wantPlay) { fbPlayer.play(); armFacebookWatchdog(); } else fbPlayer.pause();
  }

  function onFacebookReady(message) {
    if (message.type !== 'video' || cur.platform !== 'facebook' || message.id !== 'fbv' + cur.token) return;
    var token = cur.token;
    fbPlayer = message.instance;
    emit('ready', null, token);
    fbPlayer.subscribe('startedPlaying', function () {
      if (token !== cur.token) return;
      cur.fbStarted = true;
      emit('playing', null, token);
      emitDuration(fbPlayer.getDuration());
    });
    fbPlayer.subscribe('paused', function () { if (token === cur.token) emit('paused', null, token); });
    fbPlayer.subscribe('startedBuffering', function () { if (token === cur.token) emit('buffering', null, token); });
    fbPlayer.subscribe('finishedPlaying', function () {
      if (token !== cur.token) return;
      emit('ended', null, token);
      if (cur.wantPlay) { fbPlayer.seek(0); fbPlayer.play(); }
    });
    fbPlayer.subscribe('error', function (error) {
      if (token === cur.token) emit('error', {code: 'fb_' + ((error && error.code) || 'player')}, token);
    });
    if (cur.wantPlay) {
      fbApply();
    } else {
      if (cur.muted) fbPlayer.mute(); else fbPlayer.unmute();
      emit('cued', null, token);
    }
  }

  function fbAssign() {
    var token = cur.token;
    withFacebook(function () {
      if (token !== cur.token) return;
      var video = document.createElement('div');
      video.className = 'fb-video';
      video.id = 'fbv' + token;
      video.setAttribute('data-href', cur.href);
      video.setAttribute('data-width', String(Math.round(window.innerWidth)));
      video.setAttribute('data-allowfullscreen', 'false');
      video.setAttribute('data-autoplay', 'false');
      video.setAttribute('data-show-text', 'false');
      video.setAttribute('data-show-captions', 'false');
      stage.appendChild(video);
      FB.XFBML.parse(stage);
    });
  }

  // ---- Commands from Dart. ----
  function clearStage() {
    if (yt && yt.destroy) { try { yt.destroy(); } catch (e) {} }
    clearTimeout(fbWatchdog);
    ttClearSoundTimer();
    stage.innerHTML = '';
    yt = null; ytReady = false; ytVideoId = null; fbPlayer = null;
    tt = null; ttId = null; ttReady = false; ttPlaying = false; ttStarted = false; ttFailed = false;
    ttSound = false; ttSoundOk = false; ttTime = null;
  }

  // [byViewer]: the viewer paused the reel on screen (see ytHold). TikTok's
  // player shows only its still frame while paused, and Facebook pauses as
  // before, so both pause either way.
  function applyPlayback(byViewer) {
    if (cur.platform === 'youtube') {
      if (yt && ytReady) {
        if (cur.wantPlay) { if (!cur.muted) yt.unMute(); yt.playVideo(); }
        else if (byViewer) ytHold();
        else yt.pauseVideo();
      }
    } else if (cur.platform === 'tiktok') {
      ttApply();
    } else if (cur.platform === 'facebook') {
      fbApply();
    }
  }

  function applyMute() {
    if (cur.platform === 'youtube') {
      if (yt && ytReady) { if (cur.muted || !cur.wantPlay) yt.mute(); else yt.unMute(); }
    } else if (cur.platform === 'tiktok') {
      if (cur.muted) { ttSound = false; ttSend('mute'); } else if (ttPlaying) ttAskSound();
    } else if (cur.platform === 'facebook' && fbPlayer) {
      if (cur.muted) fbPlayer.mute(); else fbPlayer.unmute();
    }
  }

  window.smPlayer = {
    assign: function (token, platform, id, href, wantPlay, muted, preroll) {
      var previous = cur.platform;
      cur = blank(token);
      cur.platform = platform;
      cur.id = id;
      cur.href = href;
      cur.wantPlay = !!wantPlay;
      cur.muted = !!muted;
      cur.preroll = !!preroll && !cur.wantPlay;
      // The TikTok reel this slot already holds keeps its player: a new
      // iframe would throw away everything it has fetched.
      if (platform === 'tiktok' && previous === 'tiktok' && ttKeeps(id)) {
        ttReuse();
        return;
      }
      if (previous !== platform || platform !== 'youtube') clearStage();
      if (platform === 'youtube') ytAssign();
      else if (platform === 'tiktok') ttAssign();
      else if (platform === 'facebook') fbAssign();
      else emit('error', {code: 'unsupported_platform'});
    },
    play: function () { cur.wantPlay = true; applyPlayback(false); },
    pause: function (byViewer) { cur.wantPlay = false; applyPlayback(!!byViewer); },
    setMuted: function (muted) { cur.muted = !!muted; applyMute(); },
    retryStart: function () { if (cur.platform === 'tiktok') ttRetryStart(); },
    warm: function (origins) { warm(origins); },
    stop: function (token) { clearStage(); cur = blank(token); }
  };

  emit('host_loaded', {origin: location.origin}, 0);
})();
</script>
</body>
</html>''';
