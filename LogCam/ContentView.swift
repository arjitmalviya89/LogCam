import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var recordingManager = RecordingManager()
    @State private var cameraPermissionGranted = false
    @State private var showPermissionAlert = false

    var body: some View {
        Group {
            if cameraPermissionGranted {
                NavigationStack {
                    cameraScreen
                }
            } else {
                permissionScreen
            }
        }
        .task { await checkPermissions() }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("LogCam needs camera access to record Apple Log video.")
        }
    }

    // MARK: - Camera Screen
    private var cameraScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live preview
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            // Controls overlay
            RecordingControlsView(
                cameraManager: cameraManager,
                recordingManager: recordingManager
            )

            // Error toast
            if let error = cameraManager.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 140)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            cameraManager.configure()
            cameraManager.setOutputDelegate(delegate: recordingManager)
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    // MARK: - Permission Screen
    private var permissionScreen: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hue: 0.6, saturation: 0.8, brightness: 0.15),
                         Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                    )

                VStack(spacing: 10) {
                    Text("LogCam")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("Apple Log Video Recorder")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "apple.logo", text: "Apple Log color profile")
                    featureRow(icon: "4k.tv", text: "4K up to 60fps")
                    featureRow(icon: "waveform", text: "HEVC recording with audio")
                    featureRow(icon: "photo.on.rectangle", text: "Saves to Photos library")
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 30)

                Button(action: { Task { await requestPermissions() } }) {
                    Label("Enable Camera Access", systemImage: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 30)
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.cyan)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    // MARK: - Permissions
    private func checkPermissions() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            cameraPermissionGranted = true
        } else if status == .notDetermined {
            await requestPermissions()
        } else {
            showPermissionAlert = true
        }
    }

    private func requestPermissions() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        if granted {
            cameraPermissionGranted = true
        } else {
            showPermissionAlert = true
        }
    }
}
