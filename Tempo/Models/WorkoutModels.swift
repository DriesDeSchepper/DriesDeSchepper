import Foundation

/// User-configurable workout parameters.
struct WorkoutConfig: Equatable {
    /// Tempo digits: [eccentric, pause at bottom, concentric, pause at top].
    var tempoDigits: [Int] = [4, 0, 1, 0]
    var repsPerSet: Int = 8
    var sets: Int = 3
    var restSeconds: Int = 90

    /// A concentric digit of 0 means "explosive" — timed as 1 second.
    var concentricSeconds: Int { tempoDigits[2] == 0 ? 1 : tempoDigits[2] }

    var tempoString: String { tempoDigits.map(String.init).joined() }

    static let presets: [[Int]] = [
        [4, 0, 1, 0],
        [3, 1, 1, 0],
        [2, 0, 2, 0],
        [5, 0, 5, 0],
    ]
}

enum Phase: Equatable {
    case getReady
    case eccentric
    case pauseBottom
    case concentric
    case pauseTop
    case rest
    case done

    var title: String {
        switch self {
        case .getReady: return "GET READY"
        case .eccentric: return "ECCENTRIC"
        case .pauseBottom, .pauseTop: return "PAUSE"
        case .concentric: return "CONCENTRIC"
        case .rest: return "REST"
        case .done: return "DONE"
        }
    }

    var subtitle: String {
        switch self {
        case .getReady: return "starting"
        case .eccentric: return "lower"
        case .pauseBottom, .pauseTop: return "hold"
        case .concentric: return "lift"
        case .rest: return "breathe"
        case .done: return "nice work"
        }
    }
}

/// One slice of the precomputed workout timeline.
struct Segment {
    let phase: Phase
    let rep: Int    // 1-based; 0 for non-rep segments (get ready / rest)
    let set: Int    // 1-based
    let start: TimeInterval
    let duration: TimeInterval
    var end: TimeInterval { start + duration }
}
