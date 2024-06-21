import Foundation

class TelegramUtils {
    static func sendMessageToOwner(text: String, completion: @escaping (Bool) -> Void) {
        let ownerChatId = 0
        let token = ""
        let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage")!

        let params: [String: Any] = [
            "chat_id": ownerChatId,
            "text": text
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: params)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending message: \(error)")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Message sent successfully")
                    completion(true)
                } else {
                    print("Message not sent. Status code: \(httpResponse.statusCode)")
                    completion(false)
                }
            } else {
                print("Unexpected response format")
                completion(false)
            }
        }

        task.resume()
    }
}
