import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_host_html.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_warmup.dart';

void main() {
  final html = embedHostHtml(
    origin: 'https://app.stylemint.stylemint_mobile_frontend',
  );

  /// The page source from [start] up to the next [end].
  String section(String start, String end) {
    final from = html.indexOf(start);
    expect(from, isNonNegative, reason: start);
    final to = html.indexOf(end, from + start.length);
    expect(to, greaterThan(from), reason: end);
    return html.substring(from, to);
  }

  test('identifies the app to YouTube and keeps playback inline', () {
    expect(
      html,
      contains('var ORIGIN = "https://app.stylemint.stylemint_mobile_frontend";'),
    );
    expect(html, contains('origin: ORIGIN'));
    expect(html, contains('widget_referrer: ORIGIN'));
    expect(html, contains('playsinline: 1'));
    expect(html, contains('controls: 0'));
    expect(html, contains('https://www.youtube.com/iframe_api'));
  });

  test('never hides, restyles or scripts inside a platform player', () {
    const banned = [
      'youtube-nocookie',
      '.ytp-',
      'contentDocument',
      'MutationObserver',
      'display:none',
      'visibility:hidden',
    ];
    for (final pattern in banned) {
      expect(html, isNot(contains(pattern)), reason: pattern);
    }
  });

  test('uses the official TikTok and Facebook players', () {
    expect(html, contains('https://www.tiktok.com/player/v1/'));
    expect(html, contains("'x-tiktok-player': true"));
    expect(html, contains('https://connect.facebook.net/en_US/sdk.js'));
    expect(html, contains("video.className = 'fb-video'"));
  });

  test('embeds the origin as an escaped JavaScript string', () {
    expect(embedHostHtml(origin: 'https://a"b'), contains(r'"https://a\"b"'));
  });

  group('TikTok start-up', () {
    test('creates players with every documented hide parameter, no muted=1',
        () {
      final create = section('function ttAssign()', 'function ttReuse()');
      const params = [
        'controls=0',
        'progress_bar=0',
        'play_button=0',
        'volume_control=0',
        'fullscreen_button=0',
        'timestamp=0',
        'music_info=0',
        'description=0',
        'rel=0',
        'native_context_menu=0',
        'closed_caption=0',
        'loop=1',
        // Pre-loaded players never autoplay.
        "autoplay=' + (cur.wantPlay ? 1 : 0)",
      ];
      for (final param in params) {
        expect(create, contains(param), reason: param);
      }
      // muted=1 would lock the volume, so sound could never be turned on.
      expect(create, isNot(contains('muted=')));
    });

    test('maps every documented player state; -1 and 3 are still loading', () {
      expect(
        html,
        contains(
          "var TT_STATES = {'-1': 'init', '0': 'ended', '1': 'playing', "
          "'2': 'paused', '3': 'buffering'};",
        ),
      );
    });

    test('moving video time is reported once and brings the sound in', () {
      final time = section("case 'onCurrentTime':", 'break;');
      expect(time, contains('time.currentTime > ttTime'));
      expect(time, contains('if (advanced && cur.wantPlay) ttProgress();'));
      final progress = section(
        'function ttProgress()',
        'function ttSoundRefused()',
      );
      expect(
        progress,
        contains(
          "if (!cur.progressed) { cur.progressed = true; emit('progress'); }",
        ),
      );
      expect(progress, contains('ttAskSound()'));
      final retry = section('function ttRetryStart()', 'function ttAssign()');
      expect(retry, contains('cur.progressed) return;'));
      // A player that never reports its time is not restarted while playing.
      expect(
        retry,
        contains('if (ttPlaying && !ttTimeSeen) { ttProgress(); return; }'),
      );
      // "playing" alone never counts as moving frames.
      expect(
        section('if (data.value === 1) {', '// Paused right after asking'),
        isNot(contains('ttProgress()')),
      );
    });

    test('player errors 1001, 2001 and 3001 end the player and reach Dart', () {
      final error = section("case 'onPlayerError':", '// ---- Facebook');
      expect(error, contains('ttFailed = true;'));
      expect(error, contains("emit('error', {code: 'tt_' + code});"));
      expect(
        section('function ttKeeps(id)', 'function ttStartMuted()'),
        contains('!ttFailed'),
        reason: 'a failed player is replaced on retry, never reused',
      );
      expect(html, isNot(contains("case 'onError'")));
    });

    test('re-activating the reel a slot holds keeps its player', () {
      final assign = section('assign: function (token', 'play: function ()');
      final guard = assign.indexOf('ttKeeps(id)');
      expect(guard, isNonNegative);
      expect(guard, lessThan(assign.indexOf('clearStage()')));
      expect(guard, lessThan(assign.indexOf('ttAssign()')));
      expect(
        assign,
        matches(RegExp(r'ttKeeps\(id\)\) \{\s*ttReuse\(\);\s*return;')),
      );
      expect(
        section('function ttKeeps(id)', 'function ttStartMuted()'),
        contains('!!tt && ttReady && !ttFailed && ttId === id'),
      );
      final reuse = section(
        'function ttReuse()',
        "window.addEventListener('message'",
      );
      expect(reuse, isNot(contains('createElement')));
      expect(reuse, isNot(contains('clearStage')));
    });

    test('starts muted in one step and asks for sound once frames move', () {
      expect(
        section('function ttStartMuted()', 'function ttAskSound()'),
        matches(RegExp(r"ttSend\('mute'\);\s*ttSend\('play'\);")),
      );
      expect(
        section('function ttApply()', 'function ttRetryStart()'),
        isNot(contains('unMute')),
      );
      expect(
        RegExp(r"ttSend\('unMute'\)").allMatches(html),
        hasLength(1),
        reason: 'only ttAskSound asks for sound',
      );
      final playing = section(
        'if (data.value === 1) {',
        '// Paused right after asking for sound',
      );
      expect(
        playing.indexOf("emit('playing')"),
        lessThan(playing.indexOf('ttAskSound()')),
      );
      expect(section('function ttAskSound()', 'function ttProgress()'),
          contains("ttSend('unMute')"));
    });

    test('error 3002 carries on muted at once, in one step', () {
      expect(
        section("case 'onPlayerError':", '// 1001 invalid video'),
        contains('if (code === 3002) { ttSoundRefused(); break; }'),
      );
      final refused = section(
        'function ttSoundRefused()',
        'function ttApply()',
      );
      expect(refused, contains("emit('autoplayBlocked')"));
      expect(
        refused,
        matches(
          RegExp(
            r"ttSend\('mute'\);\s*"
            r"if \(cur\.wantPlay && retry\) ttSend\('play'\);",
          ),
        ),
      );
      expect(refused, isNot(contains('setTimeout')));
      expect(
        section(
          '// Paused right after asking for sound',
          'var state = TT_STATES',
        ),
        contains('ttSoundRefused()'),
      );
    });

    test('holds a pre-rolled reel on its first frames without reporting play',
        () {
      final playing = section(
        'if (data.value === 1) {',
        '// Paused right after asking for sound',
      );
      final offScreen = playing.substring(
        0,
        playing.indexOf("emit('playing')"),
      );
      expect(offScreen, contains("ttSend('pause')"));
      expect(offScreen, contains("emit('prerolled')"));
      expect(
        section('function ttApply()', 'function ttRetryStart()'),
        contains('cur.preroll && !ttStarted'),
      );
    });

    test('retries a stalled start muted when Dart asks', () {
      expect(
        html,
        contains(
          "retryStart: function () { if (cur.platform === 'tiktok') "
          'ttRetryStart(); }',
        ),
      );
      expect(
        section('function ttRetryStart()', 'function ttAssign()'),
        contains('ttStartMuted()'),
      );
    });

    test('warms only the official TikTok origins, with resource hints', () {
      expect(
        html,
        contains('var TT_WARM = ${jsonEncode(EmbedWarmup.tikTokOrigins)};'),
      );
      expect(
        section('function warm(origins)', '// ---- YouTube'),
        contains("['dns-prefetch', 'preconnect']"),
      );
      expect(
        section('function ttAssign()', 'function ttReuse()'),
        contains('warm(TT_WARM)'),
      );
      for (final api in ['fetch(', 'XMLHttpRequest', 'sendBeacon']) {
        expect(html, isNot(contains(api)), reason: api);
      }
    });
  });

  group('YouTube viewer pause', () {
    test('cues the video at its current time instead of pausing it', () {
      final hold = section('function ytHold()', 'function ytAssign()');
      expect(hold, contains('yt.getCurrentTime()'));
      expect(
        hold,
        contains('yt.cueVideoById({videoId: cur.id, startSeconds: at})'),
      );
      expect(hold, isNot(contains('pauseVideo')));

      final apply = section(
        'function applyPlayback(byViewer)',
        'function applyMute()',
      );
      expect(
        apply,
        matches(RegExp(r'else if \(byViewer\) ytHold\(\);\s*else yt\.pauseVideo\(\);')),
      );
      expect(
        html,
        contains(
          'pause: function (byViewer) { cur.wantPlay = false; '
          'applyPlayback(!!byViewer); }',
        ),
      );
      expect(
        html,
        contains(
          'play: function () { cur.wantPlay = true; applyPlayback(false); }',
        ),
      );
    });

    test('a stale cue never stops a reel asked to play, and a held reel is '
        'never paused into the suggestions panel', () {
      final change = section('onStateChange: function (event) {', 'onError:');
      expect(
        change,
        contains(
          'if (event.data === 5 && cur.wantPlay) '
          '{ if (cur.held) yt.playVideo(); return; }',
        ),
      );
      expect(
        change,
        contains('if (event.data === 1 && cur.wantPlay) cur.held = false;'),
      );
      expect(
        change,
        contains(
          'if (event.data === 1 && !cur.wantPlay) '
          '{ if (!cur.held) { cur.prerolled = true; yt.pauseVideo(); } }',
        ),
      );
      expect(
        section('function blank(token)', "window.addEventListener('flutter"),
        contains('held: false'),
      );
    });

    test('TikTok and Facebook pause the same way for the viewer', () {
      final apply = section(
        'function applyPlayback(byViewer)',
        'function applyMute()',
      );
      final others = apply.substring(
        apply.indexOf("cur.platform === 'tiktok'"),
      );
      expect(others, contains('ttApply();'));
      expect(others, contains('fbApply();'));
      expect(others, isNot(contains('byViewer')));
    });
  });
}
