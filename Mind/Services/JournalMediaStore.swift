import Foundation
import UIKit

/// Guarda y recupera adjuntos del diario (audio + imágenes) en el sistema de archivos
/// local del dispositivo, dentro de `Documents/Journal/`.
/// Todo queda **solo en el teléfono** del usuario; no se sube a ninguna nube.
enum JournalMediaStore {

    // MARK: — Rutas base

    private static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var root: URL { documents.appendingPathComponent("Journal", isDirectory: true) }
    static var audioDir: URL { root.appendingPathComponent("Audio", isDirectory: true) }
    static var imagesDir: URL { root.appendingPathComponent("Images", isDirectory: true) }

    /// Asegura que las carpetas existan. Llamar al arrancar la app o antes de escribir.
    @discardableResult
    static func bootstrap() -> Bool {
        do {
            try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            return true
        } catch {
            print("⚠️ JournalMediaStore bootstrap error: \(error)")
            return false
        }
    }

    // MARK: — Audio

    /// Devuelve una URL nueva para grabar audio (m4a).
    static func makeAudioURL() -> URL {
        bootstrap()
        let filename = "audio-\(UUID().uuidString).m4a"
        return audioDir.appendingPathComponent(filename)
    }

    /// Resuelve el `URL` real desde un nombre de archivo guardado en el modelo.
    static func audioURL(for fileName: String) -> URL {
        audioDir.appendingPathComponent(fileName)
    }

    static func deleteAudio(fileName: String) {
        let url = audioURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: — Imágenes

    /// Guarda una imagen como JPEG comprimido (0.8) y devuelve el nombre del archivo.
    @discardableResult
    static func saveImage(_ image: UIImage, maxDimension: CGFloat = 1600) -> String? {
        bootstrap()
        let resized = image.resizedPreservingAspect(maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "img-\(UUID().uuidString).jpg"
        let url = imagesDir.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return fileName
        } catch {
            print("⚠️ Error guardando imagen: \(error)")
            return nil
        }
    }

    static func imageURL(for fileName: String) -> URL {
        imagesDir.appendingPathComponent(fileName)
    }

    static func loadImage(fileName: String) -> UIImage? {
        UIImage(contentsOfFile: imageURL(for: fileName).path)
    }

    static func deleteImage(fileName: String) {
        let url = imageURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: — Limpieza total para una entrada

    static func deleteAllMedia(audio: String?, images: [String]) {
        if let audio { deleteAudio(fileName: audio) }
        for img in images { deleteImage(fileName: img) }
    }
}

// MARK: — UIImage resize helper

private extension UIImage {
    func resizedPreservingAspect(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
