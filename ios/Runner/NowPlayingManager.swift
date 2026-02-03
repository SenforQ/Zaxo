import AVFoundation
import Flutter
import MediaPlayer
import UIKit

final class NowPlayingManager: NSObject {
  private var channel: FlutterMethodChannel?
  private var lastInfo: [String: Any] = [:]
  private let session = AVAudioSession.sharedInstance()

  func configure(with binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.zaxo/now_playing", binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
    setupAudioSession()
    setupRemoteCommands()
  }

  private func setupAudioSession() {
    do {
      try session.setCategory(.playback, mode: .default, options: [])
      try session.setActive(true)
    } catch {
      print("NowPlayingManager: Failed to set audio session: \(error)")
    }
  }

  private func setupRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()
    center.playCommand.addTarget { [weak self] _ in
      self?.invokeFlutter("onRemotePlay")
      return .success
    }
    center.pauseCommand.addTarget { [weak self] _ in
      self?.invokeFlutter("onRemotePause")
      return .success
    }
    center.togglePlayPauseCommand.addTarget { [weak self] _ in
      self?.invokeFlutter("onRemoteTogglePlayPause")
      return .success
    }
    center.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      self?.invokeFlutter("onRemoteSeek", arguments: Int(event.positionTime * 1000))
      return .success
    }
    center.playCommand.isEnabled = true
    center.pauseCommand.isEnabled = true
    center.togglePlayPauseCommand.isEnabled = true
    center.changePlaybackPositionCommand.isEnabled = true
  }

  private func invokeFlutter(_ method: String, arguments: Any? = nil) {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod(method, arguments: arguments)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setNowPlaying":
      setNowPlaying(call.arguments, result: result)
    case "updatePlayback":
      updatePlayback(call.arguments, result: result)
    case "clearNowPlaying":
      clearNowPlaying(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setNowPlaying(_ args: Any?, result: @escaping FlutterResult) {
    guard let map = args as? [String: Any],
          let title = map["title"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "title required", details: nil))
      return
    }
    let artist = map["artist"] as? String ?? ""
    let artworkUrl = map["artworkUrl"] as? String
    let durationMs = (map["durationMs"] as? NSNumber)?.intValue ?? 0
    let durationSec = Double(durationMs) / 1000.0

    lastInfo[MPMediaItemPropertyTitle] = title
    lastInfo[MPMediaItemPropertyArtist] = artist
    lastInfo[MPMediaItemPropertyPlaybackDuration] = durationSec
    lastInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
    lastInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0

    if let urlString = artworkUrl, let url = URL(string: urlString), urlString.hasPrefix("http") {
      loadArtwork(from: url) { [weak self] image in
        if let image = image {
          let size = image.size
          self?.lastInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: size) { _ in
            image
          }
        }
        self?.applyNowPlayingInfo()
      }
    } else {
      applyNowPlayingInfo()
    }
    result(nil)
  }

  private func loadArtwork(from url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data = data, let image = UIImage(data: data) else {
        DispatchQueue.main.async { completion(nil) }
        return
      }
      DispatchQueue.main.async { completion(image) }
    }.resume()
  }

  private func updatePlayback(_ args: Any?, result: @escaping FlutterResult) {
    guard let map = args as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "map required", details: nil))
      return
    }
    let positionMs = (map["positionMs"] as? NSNumber)?.intValue ?? 0
    let isPlaying = (map["isPlaying"] as? NSNumber)?.boolValue ?? false
    let positionSec = Double(positionMs) / 1000.0
    lastInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = positionSec
    lastInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
    applyNowPlayingInfo()
    result(nil)
  }

  private func clearNowPlaying(result: @escaping FlutterResult) {
    lastInfo = [:]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    result(nil)
  }

  private func applyNowPlayingInfo() {
    if lastInfo.isEmpty {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    } else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = lastInfo
    }
  }
}
