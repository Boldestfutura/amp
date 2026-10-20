import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class PlayerModel {
    enum RepeatMode: CaseIterable {
        case off, all, one
    }

    private(set) var currentTrack: PlexTrack?
    private(set) var queue: [PlexTrack] = []
    private(set) var currentIndex: Int = 0
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    var repeatMode: RepeatMode = .off
    var isShuffled = false

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var server: PlexServer

    init(server: PlexServer) {
        self.server = server
    }

    func updateServer(_ server: PlexServer) {
        self.server = server
        player?.stop()
        player = nil
        timer?.invalidate()
        currentTrack = nil
        queue = []
        isPlaying = false
    }

    func play(track: PlexTrack, in tracks: [PlexTrack]) {
        queue = tracks
        currentIndex = tracks.firstIndex(of: track) ?? 0
        load(track)
    }

    private func load(_ track: PlexTrack) {
        guard let partKey = track.partKey,
              let url = URL(string: partKey, relativeTo: server.baseURL) else { return }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "X-Plex-Token", value: server.token)]
        guard let finalURL = components?.url else { return }

        currentTrack = track
        duration = track.durationSeconds
        currentTime = 0

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: finalURL)
                let audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                self.player = audioPlayer
                self.isPlaying = true
                self.startTimer()
            } catch {
                self.isPlaying = false
            }
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func seek(to time: Double) {
        player?.currentTime = time
        currentTime = time
    }

    func next() {
        guard !queue.isEmpty else { return }
        if isShuffled {
            currentIndex = Int.random(in: 0..<queue.count)
        } else if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else if repeatMode == .all {
            currentIndex = 0
        } else {
            return
        }
        load(queue[currentIndex])
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
        } else {
            return
        }
        load(queue[currentIndex])
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying && self.isPlaying {
                    self.handleTrackEnd()
                }
            }
        }
    }

    private func handleTrackEnd() {
        if repeatMode == .one {
            player?.currentTime = 0
            player?.play()
            return
        }
        isPlaying = false
        timer?.invalidate()
        next()
    }
}
