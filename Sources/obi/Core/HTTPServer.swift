import Foundation
import Network

/// Minimal HTTP/1.1 listener on 127.0.0.1: reads the request line, routes the path, answers text/plain.
final class HTTPServer {
    typealias Handler = (String) -> (status: Int, body: String)

    private let listener: NWListener
    private let queue = DispatchQueue(label: "obi.http")
    private let handler: Handler
    private let log: Log
    let port: UInt16

    init(port: UInt16, log: Log, handler: @escaping Handler) throws {
        self.port = port
        self.log = log
        self.handler = handler
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!)
        listener = try NWListener(using: params)
    }

    func start() {
        listener.stateUpdateHandler = { [log, port] state in
            switch state {
            case .ready: log.info("http: listening on 127.0.0.1:\(port)")
            case .failed(let error): log.error("http: failed: \(error)")
            default: break
            }
        }
        listener.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        listener.start(queue: queue)
    }

    func stop() { listener.cancel() }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        conn.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self else { conn.cancel(); return }
            let text = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
            let line = text.components(separatedBy: "\r\n").first ?? ""
            let parts = line.split(separator: " ")
            var status = 400
            var body = "bad request"
            if parts.count >= 2 {
                let path = String(parts[1]).components(separatedBy: "?").first ?? ""
                (status, body) = self.handler(path)
            }
            let reason: String
            switch status {
            case 200: reason = "OK"
            case 404: reason = "Not Found"
            default: reason = "Bad Request"
            }
            let response = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: text/plain\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
            conn.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
        }
    }
}
