import AVFoundation

/// Plays short synthesized beep cues. Tones are rendered once at init into
/// in-memory WAV data (no bundled audio files) and played via AVAudioPlayer.
///
/// The audio session uses the `.playback` category, which ignores the
/// ring/silent switch — cues are audible even when the phone is on silent.
/// `.mixWithOthers` keeps the user's music playing underneath.
final class SoundPlayer {
    enum Cue {
        case phaseChange
        case repComplete
        case setComplete
        case sideSwitch
        case workoutComplete
    }

    private var players: [Cue: AVAudioPlayer] = [:]

    /// Looping silent track. While it plays, the audio session counts as
    /// actively playing, so with the `audio` background mode iOS keeps the
    /// app running (and cues audible) when it's backgrounded or the screen
    /// is locked mid-workout.
    private var keepAlivePlayer: AVAudioPlayer?

    init() {
        // (frequency in Hz, duration in seconds); frequency 0 = silence.
        players[.phaseChange] = Self.makePlayer(tones: [(880, 0.09)])
        players[.repComplete] = Self.makePlayer(tones: [(1175, 0.09), (0, 0.05), (1175, 0.09)])
        players[.setComplete] = Self.makePlayer(tones: [(880, 0.10), (0, 0.06), (1109, 0.10), (0, 0.06), (1319, 0.20)])
        // Alternating high/low "ping-pong" pair, distinct from the other cues.
        players[.sideSwitch] = Self.makePlayer(tones: [(1400, 0.09), (0, 0.05), (700, 0.09), (0, 0.05), (1400, 0.09)])
        players[.workoutComplete] = Self.makePlayer(tones: [(1319, 0.12), (0, 0.05), (1319, 0.12), (0, 0.05), (1760, 0.35)])
        players.values.forEach { $0.prepareToPlay() }

        keepAlivePlayer = Self.makePlayer(tones: [(0, 1.0)])
        keepAlivePlayer?.numberOfLoops = -1
        keepAlivePlayer?.volume = 0
        keepAlivePlayer?.prepareToPlay()
    }

    func startKeepAlive() {
        keepAlivePlayer?.play()
    }

    func stopKeepAlive() {
        keepAlivePlayer?.stop()
    }

    func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func play(_ cue: Cue) {
        guard let player = players[cue] else { return }
        player.currentTime = 0
        player.play()
    }

    // MARK: - Tone synthesis

    private static func makePlayer(tones: [(frequency: Double, duration: Double)]) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        var samples: [Int16] = []

        for tone in tones {
            let count = Int(sampleRate * tone.duration)
            let fade = min(count / 2, Int(sampleRate * 0.005)) // 5 ms fade to avoid clicks
            for i in 0..<count {
                guard tone.frequency > 0 else {
                    samples.append(0)
                    continue
                }
                var amplitude = 0.6
                if i < fade { amplitude *= Double(i) / Double(fade) }
                if i >= count - fade { amplitude *= Double(count - i) / Double(fade) }
                let value = sin(2.0 * .pi * tone.frequency * Double(i) / sampleRate) * amplitude
                samples.append(Int16(value * Double(Int16.max)))
            }
        }

        return try? AVAudioPlayer(data: wavData(samples: samples, sampleRate: Int(sampleRate)))
    }

    /// Wraps 16-bit mono PCM samples in a minimal WAV container.
    private static func wavData(samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        let byteCount = samples.count * MemoryLayout<Int16>.size

        func ascii(_ s: String) { data.append(s.data(using: .ascii)!) }
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

        ascii("RIFF")
        u32(UInt32(36 + byteCount))
        ascii("WAVE")
        ascii("fmt ")
        u32(16)                          // fmt chunk size
        u16(1)                           // PCM
        u16(1)                           // mono
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))      // byte rate
        u16(2)                           // block align
        u16(16)                          // bits per sample
        ascii("data")
        u32(UInt32(byteCount))
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }
}
