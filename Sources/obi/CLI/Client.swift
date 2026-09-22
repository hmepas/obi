import Foundation

/// Thin HTTP client used by `obi reload|theme|refresh`.
enum Client {
    static func get(_ path: String, port: Int) -> Int32 {
        guard let url = URL(string: "http://127.0.0.1:\(port)\(path)") else { return 1 }
        let semaphore = DispatchSemaphore(value: 0)
        var exitCode: Int32 = 0
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                FileHandle.standardError.write("obi: \(error.localizedDescription)\n".data(using: .utf8)!)
                exitCode = 1
            } else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
                print(body)
                exitCode = status == 200 ? 0 : 1
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
        return exitCode
    }
}
