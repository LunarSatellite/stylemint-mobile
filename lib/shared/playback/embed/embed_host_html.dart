import 'dart:convert';

/// Builds the page an embed slot's WebView loads. [origin] is the origin the
/// platform players are told they are embedded on.
///
/// The page only drives each platform's official player API: the YouTube
/// IFrame Player API, TikTok's Embed Player over postMessage, and the Facebook
/// Embedded Video Player. It never styles, hides or scripts inside a
/// platform's player; YouTube's developer policies forbid that.
///
/// Dart talks to the page through `window.smPlayer`; the page reports back
/// through the `sm` JavaScript handler with `{token, type, ...}` events.
String embedHostHtml({required String origin}) =>
    _template.replaceFirst('__ORIGIN__', jsonEncode(origin));

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
  var stage = document.getElementById('stage');
  var cur = blank(0);
  var bridgeReady = !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler);
  var outbox = [];

  function blank(token) {
    return {token: token, platform: null, id: null, href: null, wantPlay: false,
            muted: false, durationSent: false, fbStarted: false,
            preroll: false, prerolled: false};
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
            var state = YT_STATES[String(event.data)];
            if (state) emit(state);
            if (event.data === 1) emitDuration(yt.getDuration());
            // Reels loop. Replay on end rather than the loop playerVar, which
            // needs a playlist and re-buffers from the network each pass.
            if (event.data === 0 && cur.wantPlay) { yt.seekTo(0, true); yt.playVideo(); }
            // A pre-rolling reel holds its first moving frames until it is on
            // screen, so a swipe to it shows video at once.
            if (event.data === 1 && !cur.wantPlay) { cur.prerolled = true; yt.pauseVideo(); }
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
  var tt = null;
  var TT_STATES = {'0': 'ended', '1': 'playing', '2': 'paused', '3': 'buffering'};

  function ttSend(type, value) {
    if (!tt || !tt.contentWindow) return;
    var message = {'x-tiktok-player': true, type: type};
    if (value !== undefined) message.value = value;
    tt.contentWindow.postMessage(message, '*');
  }

  function ttApply() {
    if (cur.wantPlay) { ttSend('play'); ttSend(cur.muted ? 'mute' : 'unMute'); }
    else ttSend('pause');
  }

  function ttAssign() {
    var frame = document.createElement('iframe');
    frame.src = 'https://www.tiktok.com/player/v1/' + encodeURIComponent(cur.id) +
      '?controls=0&progress_bar=0&play_button=0&volume_control=0&fullscreen_button=0' +
      '&timestamp=0&music_info=0&description=0&rel=0&native_context_menu=0' +
      '&closed_caption=0&loop=1&autoplay=' + (cur.wantPlay ? 1 : 0);
    frame.setAttribute('allow', 'autoplay; encrypted-media; fullscreen');
    stage.appendChild(frame);
    tt = frame;
  }

  window.addEventListener('message', function (event) {
    if (cur.platform !== 'tiktok' || !tt || event.source !== tt.contentWindow) return;
    var data = event.data;
    if (typeof data === 'string') { try { data = JSON.parse(data); } catch (e) { return; } }
    if (!data || !data['x-tiktok-player']) return;
    switch (data.type) {
      case 'onPlayerReady':
        emit('ready');
        if (cur.wantPlay) ttApply(); else emit('cued');
        break;
      case 'onStateChange':
        var state = TT_STATES[String(data.value)];
        if (state) emit(state);
        // The player starts muted; ask for sound once frames are moving.
        if (data.value === 1 && !cur.muted) ttSend('unMute');
        break;
      case 'onCurrentTime':
        if (data.value && data.value.duration) emitDuration(data.value.duration);
        break;
      case 'onMute':
        emit('muted', {value: !!data.value});
        break;
      case 'onPlayerError':
        var code = data.value && data.value.errorCode;
        if (code === 3002) {
          cur.muted = true;
          emit('autoplayBlocked');
          ttSend('mute');
          if (cur.wantPlay) ttSend('play');
        } else {
          emit('error', {code: 'tt_' + code});
        }
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
    stage.innerHTML = '';
    yt = null; ytReady = false; ytVideoId = null; tt = null; fbPlayer = null;
  }

  function applyPlayback() {
    if (cur.platform === 'youtube') {
      if (yt && ytReady) {
        if (cur.wantPlay) { if (!cur.muted) yt.unMute(); yt.playVideo(); } else yt.pauseVideo();
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
      ttSend(cur.muted ? 'mute' : 'unMute');
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
      if (previous !== platform || platform !== 'youtube') clearStage();
      if (platform === 'youtube') ytAssign();
      else if (platform === 'tiktok') ttAssign();
      else if (platform === 'facebook') fbAssign();
      else emit('error', {code: 'unsupported_platform'});
    },
    play: function () { cur.wantPlay = true; applyPlayback(); },
    pause: function () { cur.wantPlay = false; applyPlayback(); },
    setMuted: function (muted) { cur.muted = !!muted; applyMute(); },
    stop: function (token) { clearStage(); cur = blank(token); }
  };

  emit('host_loaded', {origin: location.origin}, 0);
})();
</script>
</body>
</html>''';
