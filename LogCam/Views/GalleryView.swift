import SwiftUI

struct GalleryView: View {
    let sessions: [RecordingSession]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No recordings yet")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 16))
                }
            } else {
                List(sessions) { session in
                    sessionRow(session)
                        .listRowBackground(Color.white.opacity(0.05))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sessionRow(_ session: RecordingSession) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(session.isAppleLog ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 54, height: 54)
                Image(systemName: "film")
                    .font(.system(size: 22))
                    .foregroundColor(session.isAppleLog ? .green : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if session.isAppleLog {
                        Text("LOG")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                Text("\(session.resolution) • \(session.fps) fps • \(session.formattedDuration)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}


// MARK: - Settings Sheet
struct SettingsSheet: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var recordingManager: RecordingManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()
                Form {
                    Section("Resolution") {
                        ForEach(Resolution.allCases) { res in
                            HStack {
                                Text(res.rawValue)
                                    .foregroundColor(.white)
                                Spacer()
                                if cameraManager.selectedResolution == res {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { cameraManager.selectedResolution = res }
                        }
                    }

                    Section("Frame Rate") {
                        ForEach(FrameRate.allCases) { fps in
                            HStack {
                                Text(fps.label)
                                    .foregroundColor(.white)
                                Spacer()
                                if cameraManager.selectedFPS == fps {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { cameraManager.selectedFPS = fps }
                        }
                    }

                    Section("Apple Log") {
                        Toggle("Enable Apple Log", isOn: Binding(
                            get: { cameraManager.isAppleLogEnabled },
                            set: { _ in cameraManager.toggleAppleLog() }
                        ))
                        .tint(.green)
                        .disabled(!cameraManager.isAppleLogSupported)

                        if !cameraManager.isAppleLogSupported {
                            Text("Apple Log requires iPhone 15 Pro or later")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
