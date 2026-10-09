@preconcurrency import AVFoundation
import UIKit

/// Live ISBN preview on Pack. The session stays up across codes and stops when
/// the sheet closes or the app backgrounds. QR payloads yield an 8 to 14 digit run.
final class ISBNCapture: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    let preview = AVCaptureVideoPreviewLayer()
    var onCode: ((String) -> Void)?
    private let queue = DispatchQueue(label: "cordillera.isbn")
    private var running = false
    private var armed = false
    private var frames = 0
    private var lastPayload = ""
    private var lastEmit = Date.distantPast

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            armed = true
            configureAndRun()
        case .notDetermined, .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func stop() {
        armed = false
        haltSession()
    }

    @objc private func didBackground() {
        haltSession()
    }

    @objc private func didForeground() {
        guard armed else { return }
        configureAndRun()
    }

    private func haltSession() {
        guard running else { return }
        running = false
        queue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func configureAndRun() {
        guard !running else { return }
        if !session.inputs.isEmpty {
            running = true
            queue.async { [session] in
                if !session.isRunning { session.startRunning() }
            }
            return
        }
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if (try? device.lockForConfiguration()) != nil {
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: queue)
        let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce, .qr, .code128]
        output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }
        session.commitConfiguration()
        preview.session = session
        preview.videoGravity = .resizeAspectFill
        running = true
        queue.async { [session] in
            session.startRunning()
        }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let raw = object.stringValue else { return }
        let digits = Self.isbnDigits(from: raw)
        guard let digits else { return }
        queue.async { [weak self] in
            self?.emit(digits)
        }
    }

    private func emit(_ digits: String) {
        frames += 1
        if frames % 3 != 0 { return }
        let now = Date()
        if digits == lastPayload, now.timeIntervalSince(lastEmit) < 1.6 { return }
        lastPayload = digits
        lastEmit = now
        DispatchQueue.main.async { [weak self] in
            self?.onCode?(digits)
        }
    }

    /// Digit runs of 8 to 14. A 12-digit UPC-A is prefixed to a 13-digit EAN.
    static func isbnDigits(from raw: String) -> String? {
        let runs = raw.split { !$0.isNumber }.map(String.init).compactMap { piece -> String? in
            guard (8...14).contains(piece.count) else { return nil }
            if piece.count == 12 { return "0" + piece }
            return piece
        }
        return runs.first { $0.count == 13 } ?? runs.first
    }
}
