import Foundation

// MARK: - Error

enum APIError: LocalizedError {
    case unauthorized
    case forbidden
    case badRequest(String)
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:      return "Sesión expirada. Inicia sesión de nuevo."
        case .forbidden:         return "No tienes permisos para esta acción."
        case .badRequest(let m): return m
        case .networkError(let e): return "Sin conexión: \(e.localizedDescription)"
        case .decodingError:     return "Error al procesar la respuesta del servidor."
        case .serverError(let c): return "Error del servidor (\(c))."
        }
    }
}

// MARK: - Client

final class APIClient {
    static let shared = APIClient()
    private init() {}

    static let baseURL = "https://satirical-illusion-unquote.ngrok-free.dev/api/v1"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Token

    var token: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userRole")
    }

    // MARK: - Request Builder

    private func buildRequest(method: String, path: String, body: (any Encodable)? = nil) throws -> URLRequest {
        guard let url = URL(string: APIClient.baseURL + path) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        // Required to bypass ngrok browser interstitial
        req.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }
        return req
    }

    // MARK: - Public Methods

    func get<T: Decodable>(_ path: String) async throws -> T {
        let req = try buildRequest(method: "GET", path: path)
        return try await execute(req)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let req = try buildRequest(method: "POST", path: path, body: body)
        return try await execute(req)
    }

    func postDiscardingResponse<Body: Encodable>(_ path: String, body: Body) async throws {
        let req = try buildRequest(method: "POST", path: path, body: body)
        let (_, response) = try await URLSession.shared.data(for: req)
        try validate(response)
    }

    // MARK: - Private

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response)
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        default:  throw APIError.serverError(http.statusCode)
        }
    }
}
