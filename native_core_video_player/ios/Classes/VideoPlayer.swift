import AVFoundation
import Flutter
import UIKit

class VideoPlayer: NSObject, FlutterTexture {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var textureRegistry: FlutterTextureRegistry
    private var textureId: Int64 = -1
    private var eventSink: ((Any) -> Void)?
    private var timeObserver: Any?
    private var isInitialized = false
    private var displayLink: CADisplayLink?
    
    init(textureRegistry: FlutterTextureRegistry, eventSink: @escaping (Any) -> Void) {
        self.textureRegistry = textureRegistry
        self.eventSink = eventSink
        super.init()
        
        setupNotifications()
    }
    
    func initialize(source: String) {
        guard let url = URL(string: source) else {
            sendError(code: "invalid_url", message: "Invalid video URL")
            return
        }
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session configuration failed, but continue anyway
            print("Failed to configure audio session: \(error)")
        }
        
        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
        
        if let videoOutput = videoOutput {
            playerItem?.add(videoOutput)
        }
        
        player = AVPlayer(playerItem: playerItem)
        
        textureId = textureRegistry.register(self)
        
        addObservers()
        setupDisplayLink()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func addObservers() {
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil)
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updatePosition()
        }
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func displayLinkCallback() {
        textureRegistry.textureFrameAvailable(textureId)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    if !isInitialized {
                        isInitialized = true
                        let duration = CMTimeGetSeconds(item.duration)
                        let size = item.presentationSize
                        sendEvent(event: "initialized", data: [
                            "duration": Int64(duration * 1000),
                            "width": Int(size.width),
                            "height": Int(size.height)
                        ])
                        // Send initial position update so metadata is visible
                        updatePosition()
                    }
                    // Only send paused state if player is not actually playing
                    // This prevents overriding the playing state when play() is called
                    if let player = player, player.rate == 0.0 {
                        sendEvent(event: "state", data: "paused")
                    }
                case .failed:
                    sendError(code: "playback_error", message: item.error?.localizedDescription ?? "Unknown error")
                default:
                    break
                }
            }
        } else if keyPath == "loadedTimeRanges" {
            updateBufferedPosition()
        }
    }
    
    func play() {
        guard let player = player else { return }
        player.rate = 1.0
        sendEvent(event: "state", data: "playing")
    }
    
    func pause() {
        guard let player = player else { return }
        player.rate = 0.0
        sendEvent(event: "state", data: "paused")
    }
    
    func seekTo(position: Int64) {
        let time = CMTime(value: position, timescale: 1000)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            if finished {
                self?.updatePosition()
            }
        }
    }
    
    func setVolume(volume: Float) {
        player?.volume = max(0.0, min(1.0, volume))
    }
    
    func setPlaybackSpeed(speed: Float) {
        player?.rate = speed
    }
    
    func setLooping(looping: Bool) {
        if looping {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        sendEvent(event: "state", data: "completed")
        player?.seek(to: .zero)
        player?.rate = 1.0
    }
    
    @objc private func appDidEnterBackground() {
        player?.rate = 0.0
    }
    
    @objc private func appWillEnterForeground() {
    }
    
    private func updatePosition() {
        guard let player = player, let item = playerItem else { return }
        
        let position = CMTimeGetSeconds(player.currentTime())
        let buffered = getBufferedPosition()
        let duration = CMTimeGetSeconds(item.duration)
        
        sendEvent(event: "position", data: [
            "position": Int64(position * 1000),
            "bufferedPosition": Int64(buffered * 1000),
            "duration": Int64(duration * 1000)
        ])
    }
    
    private func updateBufferedPosition() {
        let buffered = getBufferedPosition()
        sendEvent(event: "buffered", data: Int64(buffered * 1000))
    }
    
    private func getBufferedPosition() -> Double {
        guard let item = playerItem, let timeRange = item.loadedTimeRanges.first?.timeRangeValue else {
            return 0
        }
        let buffered = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
        return buffered
    }
    
    func dispose() {
        displayLink?.invalidate()
        displayLink = nil
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        
        NotificationCenter.default.removeObserver(self)
        
        player?.rate = 0.0
        player = nil
        playerItem = nil
        videoOutput = nil
        
        if textureId >= 0 {
            textureRegistry.unregisterTexture(textureId)
        }
    }
    
    func getTextureId() -> Int64 {
        return textureId
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let videoOutput = videoOutput, let item = playerItem else {
            return nil
        }
        
        let time = item.currentTime()
        
        if videoOutput.hasNewPixelBuffer(forItemTime: time) {
            if let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) {
                return Unmanaged.passRetained(pixelBuffer)
            }
        }
        
        return nil
    }
    
    private func sendEvent(event: String, data: Any) {
        eventSink?(["event": event, "data": data])
    }
    
    private func sendError(code: String, message: String) {
        eventSink?(["event": "error", "data": ["code": code, "message": message]])
    }
}
