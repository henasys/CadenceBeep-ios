import AVFoundation
import Combine

enum BeepSound: String, CaseIterable, Identifiable {
    case high = "높은톤"
    case low = "낮은톤"
    case click = "클릭"

    var id: String { rawValue }

    var frequency: Double {
        switch self {
        case .high: return 1200
        case .low: return 600
        case .click: return 2400
        }
    }

    var duration: Double {
        switch self {
        case .high: return 0.04
        case .low: return 0.06
        case .click: return 0.015
        }
    }
}

final class BeepEngine: ObservableObject {
    @Published var spm: Int = 170
    @Published var isPlaying = false
    @Published var volume: Float = 0.7
    @Published var beepSound: BeepSound = .high
    @Published var accentEvery: Int = 0 // 0 = off

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timer: DispatchSourceTimer?
    private var beatCount: Int = 0

    private let sampleRate: Double = 44100

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func start() {
        stop()
        configureAudioSession()

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()

        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.play()
        } catch {
            print("Engine start error: \(error)")
            return
        }

        self.audioEngine = engine
        self.playerNode = player
        self.beatCount = 0
        self.isPlaying = true

        scheduleBeeps()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        isPlaying = false
        beatCount = 0
    }

    private func scheduleBeeps() {
        let interval = 60.0 / Double(spm)
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: interval)

        timer.setEventHandler { [weak self] in
            self?.playBeep()
        }

        timer.resume()
        self.timer = timer
    }

    private func playBeep() {
        guard let player = playerNode, let engine = audioEngine, engine.isRunning else { return }

        beatCount += 1
        let isAccent = accentEvery > 0 && (beatCount % accentEvery == 1 || accentEvery == 1)

        let sound = beepSound
        let freq = isAccent ? sound.frequency * 1.5 : sound.frequency
        let dur = isAccent ? sound.duration * 1.5 : sound.duration
        let vol = self.volume * (isAccent ? 1.0 : 0.75)

        let frameCount = AVAudioFrameCount(dur * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: player.outputFormat(forBus: 0), frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample = Float(sin(2.0 * .pi * freq * t))

            // Envelope: quick attack, quick decay
            let attackFrames = Int(0.002 * sampleRate)
            let decayStart = Int(Double(frameCount) * 0.3)
            if i < attackFrames {
                sample *= Float(i) / Float(attackFrames)
            } else if i > decayStart {
                let decayProgress = Float(i - decayStart) / Float(Int(frameCount) - decayStart)
                sample *= 1.0 - decayProgress
            }

            sample *= vol
            data[i] = sample
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    func updateTiming() {
        if isPlaying {
            timer?.cancel()
            timer = nil
            scheduleBeeps()
        }
    }
}
