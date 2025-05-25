import SwiftUI
import Foundation
import UIKit
import AVFoundation
import Photos

struct CameraView: View {
    @ObservedObject var model: Model
    
    @StateObject private var cameraManager = CameraManager()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var photoCaptured = false
    @State private var displayedImage: UIImage?
    @State private var imageCaption: String?
    @State private var healthScore = 0.0
    
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        ZStack {
            
            
            // Camera preview
            ZStack {
                if let image = displayedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .transition(.opacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                displayedImage = nil
                            }
                        }
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
                if displayedImage == nil {
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
                    print("DEBUG: Starting upload task")
                    do {
                        print("DEBUG: Calling uploadImage")
                        let (caption, score) = try await uploadImage(image)
                        print("DEBUG: uploadImage returned caption: \(caption), healthScore: \(score)")
                        imageCaption = caption
                        healthScore = score
                    } catch {
                        print("DEBUG: uploadImage error: \(error)")
                        alertMessage = "Upload failed: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
            
            
            if displayedImage != nil {
                let numHealthScore = Int(healthScore)
                
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.regularMaterial)
                        .frame(height: 170)
                        .shadow(radius: 25)
                        .overlay {
                            if let imageCaption = imageCaption {
                                VStack {
                                    HStack {
                                        Text(imageCaption.uppercased())
                                            .font(.title2)
                                            .bold()
                                        
                                        
                                        Spacer()
                                        
//                                        Circle()
//                                            .frame(width: 40, height: 40)
//                                            .overlay {
                                        let color = {
                                            if numHealthScore < 0 {
                                                return Color.red
                                            } else if self.healthScore == 0 {
                                                return Color.yellow
                                            } else {
                                                return Color.green
                                            }
                                        }()
                                                Text(String(format: "%.1f", healthScore))
                                                    .foregroundStyle(color)
                                                    .bold()
                                                    .font(.system(size: 25))
//                                            }
                                    }
                                    Spacer()
                                    
                                    Button {
                                        dismiss()
                                        model.gutScore += numHealthScore
                                    } label: {
                                        Capsule()
                                            .foregroundStyle(.black)
                                            .overlay {
                                                Text("Confirm")
                                                    .foregroundStyle(.white)
                                            }
                                    }
                                    .frame(width: 200, height: 50)
                                }
                                .padding()
                            } else {
                                Text("Analyzing...")
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                        }
                        
                }
                .padding()
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
    }

    private func uploadImage(_ image: UIImage) async throws -> (String, Double) {
        print("DEBUG: uploadImage called")

        guard let url = URL(string: "\(baseUrl)/camera") else {
            throw URLError(.badURL)
        }
        print("DEBUG: URL is \(url)")

        var request = URLRequest(url: url)
        print("DEBUG: URLRequest created: \(request)")
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        print("DEBUG: Boundary: \(boundary)")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG: Image compression failed")
            throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image compression failed"])
        }
        print("DEBUG: Image data size: \(imageData.count) bytes")

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
        print("DEBUG: HTTP body size: \(body.count) bytes")

        let (data, response) = try await URLSession.shared.data(for: request)
        print("DEBUG: Received response, status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let errorMsg = json["error"] as? String {
                throw NSError(domain: "Upload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            throw NSError(domain: "Upload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]
        print("DEBUG: Parsed JSON response: \(json ?? [:])")

        if let captionDict = json?["caption"] as? [String: Any],
           let detectedFood = captionDict["detected_food"] as? String,
           let healthScoreValue = captionDict["health_score"] as? Double {
            print("DEBUG: Returning caption: \(detectedFood), healthScore: \(healthScoreValue)")
            return (detectedFood, healthScoreValue)
        } else {
            print("DEBUG: JSON structure invalid: \(json ?? [:])")
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
    CameraView(model: Model())
}

extension Notification.Name {
    static let photoCaptured = Notification.Name("photoCaptured")
}
