import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAudioSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Lets reels be heard.
  ///
  /// The app set no `AVAudioSession` category at all, so iOS left it on the
  /// default — `soloAmbient`, which the hardware ring/silent switch mutes.
  /// Every reel therefore played silently for anyone with the switch on, on
  /// both the WebView embeds (TikTok, YouTube, Facebook) and the native
  /// player, with nothing on screen to explain it.
  ///
  /// `.playback` is the category Apple documents for media whose audio is the
  /// point, and it is what every reels app does: sound plays with the switch
  /// on. The trade is that when this session goes active it interrupts
  /// whatever else was playing — the viewer's music stops when a reel starts.
  /// That is the standard behaviour for this kind of app; use
  /// `.mixWithOthers` here instead if StyleMint should defer to other audio.
  ///
  /// The session is deliberately NOT activated here. Setting the category
  /// only declares intent; activating it is what interrupts other apps, and
  /// doing that at launch would kill the viewer's music the moment they open
  /// StyleMint, before a single reel has played. The media stack activates it
  /// when playback actually starts.
  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .moviePlayback,
        options: []
      )
    } catch {
      // A refused category is not a reason to fail launch — playback still
      // works, just muted by the silent switch, as it did before.
      NSLog("StyleMint: could not set AVAudioSession category: \(error)")
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
