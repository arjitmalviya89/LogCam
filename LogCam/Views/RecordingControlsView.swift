import SwiftUI

struct RecordingControlsView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var recordingManager: RecordingManager

    @State private var showSettings = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            // --- Top HUD ---
            topHUD
            Spacer()
            // --- Bottom Controls ---
            bottomControls
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(cameraManager: cameraManager, recordingManager: recordingManager)
        }
    }

    // MARK: - Top HUD
    private var topHUD: some View {
        HStack(spacing: 12) {
            // Apple Log badge
            logBadge
            Spacer()
            // Recording timer
            if recordingManager.isRecording {
                recordingTimer
            }
            Spacer()
            // Settings button
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Apple Log Badge
    private var logBadge: some View {
        Button(action: { cameraManager.toggleAppleLog() }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(cameraManager.isAppleLogEnabled ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(cameraManager.isAppleLogEnabled ? "LOG" : "STD")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(cameraManager.isAppleLogEnabled ? .green : .white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cameraManager.isAppleLogEnabled
                          ? Color.green.opacity(0.2)
                          : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(cameraManager.isAppleLogEnabled
                                    ? Color.green.opacity(0.5)
                                    : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .disabled(!cameraManager.isAppleLogSupported)
        .opacity(cameraManager.isAppleLogSupported ? 1 : 0.4)
    }

    // MARK: - Recording Timer
    private var recordingTimer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseAnimation ? 1.3 : 0.9)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                           value: pulseAnimation)
                .onAppear { pulseAnimation = true }
                .onDisappear { pulseAnimation = false }
            Text(formatDuration(recordingManager.recordingDuration))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Resolution + FPS pills
            HStack(spacing: 10) {
                ForEach(FrameRate.allCases) { fps in
                    fpsPill(fps)
                }
            }

            // Record button row
            HStack(spacing: 40) {
                // Gallery thumbnail placeholder
                NavigationLink(destination: GalleryView(sessions: recordingManager.savedSessions)) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .foregroundColor(.white.opacity(0.7))
                        )
                }

                // Main record button
                recordButton

                // Flip camera (placeholder)
                Button(action: {}) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(.bottom, 50)
    }

    // MARK: - FPS Pill
    private func fpsPill(_ fps: FrameRate) -> some View {
        let selected = cameraManager.selectedFPS == fps
        return Button(action: {
            cameraManager.selectedFPS = fps
        }) {
            Text(fps.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(selected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(selected ? Color.white : Color.white.opacity(0.15))
                )
        }
    }

    // MARK: - Record Button
    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 78, height: 78)

                if recordingManager.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                        .transition(.scale)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 62, height: 62)
                        .transition(.scale)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recordingManager.isRecording)
        }
    }

    // MARK: - Actions
    private func toggleRecording() {
        if recordingManager.isRecording {
            recordingManager.stopRecording(
                isAppleLog: cameraManager.isAppleLogEnabled,
                resolution: cameraManager.selectedResolution,
                fps: cameraManager.selectedFPS
            )
        } else {
            recordingManager.startRecording(
                isAppleLog: cameraManager.isAppleLogEnabled,
                resolution: cameraManager.selectedResolution,
                fps: cameraManager.selectedFPS
            )
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
