import SwiftUI
import Foundation
import AVFoundation
import Photos

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var photoCaptured = false
    @State private var displayedImage: UIImage?
    @State private var imageCaption: String?
    
    var body: some View {
        ZStack {
            
            
            // Camera preview
            ZStack {
                if let image = displayedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                displayedImage = nil
                            }
                        }
                        .offset(y:  -150)
                } else {
                    CameraPreview(session: cameraManager.session)
                        .ignoresSafeArea()
                }
            }
            .overlay(alignment: .top) {
                if displayedImage == nil {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 300, weight: .thin))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 100)
                }
            }
            .overlay(alignment: .bottom) {
                Circle()
                    .stroke(Color.white.opacity(1), lineWidth: 2)
                    .overlay {
                        Button {
                            cameraManager.capturePhoto()
                            withAnimation {
                                photoCaptured = true
                            }
                            
                        } label: {
                            Circle()
                                .foregroundStyle(.white)
                                .padding(4)
                        }
                    }
                    .frame(width: 80, height: 80)
            }
            .onReceive(NotificationCenter.default.publisher(for: .photoCaptured)) { _ in
                withAnimation {
                    photoCaptured = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        photoCaptured = false
                    }
                }
            }
            .onReceive(cameraManager.$capturedImage.compactMap { $0 }) { image in
                withAnimation {
                    displayedImage = image
                }

                Task {
                    // HERE
                    do {
                        let caption = try await uploadImage(image)
                        imageCaption = caption
                    } catch {
                        alertMessage = "Upload failed: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }

            }
            
            
            if displayedImage != nil {
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.white)
                        .frame(height: 400)
                        .shadow(radius: 25)
                        
                }
                .ignoresSafeArea()
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
    }

    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let url = URL(string: "\(baseUrl)/camera") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image compression failed"])
        }

        var body = Data()
        let filename = "upload.jpg"
        let mimeType = "image/jpeg"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        // Parse HTTP response and JSON
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        if !(200...299).contains(httpResponse.statusCode) {
            // Try decode error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let errorMsg = json["error"] as? String {
                throw NSError(domain: "Upload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            throw NSError(domain: "Upload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        // Decode caption
        let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]
        if let caption = json?["caption"] as? String {
            return caption
        } else {
            throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }
    }
}








struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionRunning = false
    @Published var alertMessage = ""
    @Published var capturedImage: UIImage?
    
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.alertMessage = "Camera access is required to take photos"
                    }
                }
            }
        case .denied, .restricted:
            alertMessage = "Camera access denied. Please enable in Settings."
        @unknown default:
            alertMessage = "Unknown camera authorization status"
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Configure session preset
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Add video input (main camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                       position: .back) else {
            alertMessage = "Could not find main camera"
            session.commitConfiguration()
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                alertMessage = "Could not add video device input to the session"
                session.commitConfiguration()
                return
            }
        } catch {
            alertMessage = "Could not create video device input: \(error.localizedDescription)"
            session.commitConfiguration()
            return
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            alertMessage = "Could not add photo output to the session"
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        // Configure photo settings for high quality
        settings.isHighResolutionPhotoEnabled = true
        
        // Enable flash if available
        if let videoDeviceInput = videoDeviceInput,
           videoDeviceInput.device.hasFlash {
            settings.flashMode = .auto
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        
        if let error = error {
            DispatchQueue.main.async {
                self.alertMessage = "Photo capture failed: \(error.localizedDescription)"
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.alertMessage = "Could not convert photo to image"
            }
            return
        }
        
        self.capturedImage = image
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .photoCaptured, object: nil)
        }
    }
}


#Preview {
    CameraView()
}

extension Notification.Name {
    static let photoCaptured = Notification.Name("photoCaptured")
}
