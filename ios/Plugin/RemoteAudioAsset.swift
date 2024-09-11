import AVFoundation

public class RemoteAudioAsset: AudioAsset {
    var playerItem: AVPlayerItem?
    var player: AVPlayer?

    override init(owner: NativeAudio, withAssetId assetId: String, withPath path: String!, withChannels channels: Int!, withVolume volume: Float!, withFadeDelay delay: Float!) {
        super.init(owner: owner, withAssetId: assetId, withPath: path, withChannels: channels, withVolume: volume, withFadeDelay: delay)

        if let url = URL(string: path) {
            self.playerItem = AVPlayerItem(url: url)
            self.playerItem?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
            self.player = AVPlayer(playerItem: self.playerItem)
            self.player?.volume = volume
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.playerItem, queue: nil) { _ in
                print("播放已完成")
                // 在这里处理播放完成的逻辑
            }
            // 确保在不需要监听时移除观察者
//            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        }
    }
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
            if playerItem.status == .failed {
                print("Error: \(String(describing: playerItem.error))")
            }
        }
    }

    override func play(time: TimeInterval, delay: TimeInterval) {
        guard let player = self.player else { return }
        if delay > 0 {
            // Calculate the future time to play
            let timeToPlay = CMTimeAdd(CMTimeMakeWithSeconds(player.currentTime().seconds, preferredTimescale: 1), CMTimeMakeWithSeconds(delay, preferredTimescale: 1))
            player.seek(to: timeToPlay)
        } else {
            player.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: 1))
        }
        player.play()
    }

    override func pause() {
        player?.pause()
    }

    override func resume() {
        player?.play()
    }

    override func stop() {
        player?.pause()
        player?.seek(to: CMTime.zero)
    }

    override func loop() {
        player?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem)
        player?.play()
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        player?.seek(to: CMTime.zero)
        player?.play()
    }

    override func unload() {
        stop()
        NotificationCenter.default.removeObserver(self)
        player = nil
        playerItem = nil
    }

    override func setVolume(volume: NSNumber!) {
        player?.volume = volume.floatValue
    }

    override func setRate(rate: NSNumber!) {
        player?.rate = rate.floatValue
    }

    override func isPlaying() -> Bool {
        return player?.timeControlStatus == .playing
    }
}
