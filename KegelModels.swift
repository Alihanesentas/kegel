import Foundation

// MARK: - Egzersiz fazları

enum Phase: String, Codable, CaseIterable {
    case prepare    // hazırlan
    case contract   // sık
    case hold       // tut
    case relax      // bırak
    case rest       // setler arası dinlenme
    case finished

    /// Ekranda gösterilen kısa komut.
    var label: String {
        switch self {
        case .prepare:  return "Hazırlan"
        case .contract: return "Sık"
        case .hold:     return "Tut"
        case .relax:    return "Bırak"
        case .rest:     return "Dinlen"
        case .finished: return "Bitti"
        }
    }

    /// Sesli komut. Kısa tutuluyor: uzun cümle zamanlamayı kaçırtıyor.
    var spokenCue: String? {
        switch self {
        case .prepare:  return "Hazırlan"
        case .contract: return "Sık"
        case .hold:     return "Tut"
        case .relax:    return "Bırak"
        case .rest:     return "Dinlen"
        case .finished: return "Tamamlandı"
        }
    }

    /// Nefes halkasının bu fazda ne kadar büyüdüğü (0–1).
    var ringScale: Double {
        switch self {
        case .contract, .hold: return 1.0
        case .relax:           return 0.0
        case .prepare, .rest:  return 0.35
        case .finished:        return 0.5
        }
    }
}

// MARK: - Tek bir adım

struct WorkoutStep: Identifiable, Equatable {
    let id = UUID()
    let phase: Phase
    let duration: TimeInterval
    let repIndex: Int?   // 1'den başlar
    let setIndex: Int?   // 1'den başlar
}

// MARK: - Seviye

struct Level: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let contract: TimeInterval
    let hold: TimeInterval        // 0 ise "tut" fazı atlanır
    let relax: TimeInterval
    let reps: Int
    let sets: Int
    let restBetweenSets: TimeInterval

    var prepare: TimeInterval { 5 }

    var totalDuration: TimeInterval {
        let perRep = contract + hold + relax
        let work = perRep * Double(reps) * Double(sets)
        let rest = restBetweenSets * Double(max(0, sets - 1))
        return prepare + work + rest
    }

    var totalReps: Int { reps * sets }

    /// Seviyeyi düz bir adım listesine çevirir. Motor sadece bu listeyi yürütür.
    func buildSteps() -> [WorkoutStep] {
        var steps: [WorkoutStep] = [
            WorkoutStep(phase: .prepare, duration: prepare, repIndex: nil, setIndex: nil)
        ]

        for set in 1...sets {
            for rep in 1...reps {
                steps.append(WorkoutStep(phase: .contract, duration: contract, repIndex: rep, setIndex: set))
                if hold > 0 {
                    steps.append(WorkoutStep(phase: .hold, duration: hold, repIndex: rep, setIndex: set))
                }
                steps.append(WorkoutStep(phase: .relax, duration: relax, repIndex: rep, setIndex: set))
            }
            if set < sets {
                steps.append(WorkoutStep(phase: .rest, duration: restBetweenSets, repIndex: nil, setIndex: set))
            }
        }
        return steps
    }
}

extension Level {
    /// Kademeli program. Süreler kısa başlayıp yavaş artıyor — asıl mesele
    /// doğru kası izole etmek, ilk günden 10 saniye tutmaya çalışmak değil.
    static let catalog: [Level] = [
        Level(id: 1, title: "Başlangıç",     subtitle: "Kası tanı",          contract: 3, hold: 0, relax: 4, reps: 8,  sets: 1, restBetweenSets: 0),
        Level(id: 2, title: "Temel ritim",   subtitle: "Sık ve tam bırak",   contract: 3, hold: 0, relax: 4, reps: 10, sets: 2, restBetweenSets: 20),
        Level(id: 3, title: "Tutuş",         subtitle: "Kısa tutmalar",      contract: 2, hold: 3, relax: 5, reps: 10, sets: 2, restBetweenSets: 20),
        Level(id: 4, title: "Dayanıklılık",  subtitle: "Daha uzun tutuş",    contract: 2, hold: 5, relax: 5, reps: 10, sets: 2, restBetweenSets: 25),
        Level(id: 5, title: "Kontrol",       subtitle: "Yavaş ve kontrollü", contract: 3, hold: 6, relax: 6, reps: 10, sets: 3, restBetweenSets: 30),
        Level(id: 6, title: "Güç",           subtitle: "Üç set",             contract: 3, hold: 8, relax: 6, reps: 12, sets: 3, restBetweenSets: 30),
        Level(id: 7, title: "İleri",         subtitle: "Uzun tutuşlar",      contract: 3, hold: 10, relax: 7, reps: 12, sets: 3, restBetweenSets: 35),
        Level(id: 8, title: "Ustalık",       subtitle: "Tam program",        contract: 3, hold: 12, relax: 8, reps: 12, sets: 4, restBetweenSets: 40)
    ]

    static func level(id: Int) -> Level {
        catalog.first { $0.id == id } ?? catalog[0]
    }
}

// MARK: - Kayıt

struct SessionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let levelID: Int
    let completedReps: Int
    let plannedReps: Int
    let duration: TimeInterval
    let wasCompleted: Bool

    init(id: UUID = UUID(),
         date: Date = Date(),
         levelID: Int,
         completedReps: Int,
         plannedReps: Int,
         duration: TimeInterval,
         wasCompleted: Bool) {
        self.id = id
        self.date = date
        self.levelID = levelID
        self.completedReps = completedReps
        self.plannedReps = plannedReps
        self.duration = duration
        self.wasCompleted = wasCompleted
    }
}
