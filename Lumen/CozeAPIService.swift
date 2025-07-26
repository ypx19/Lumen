import Foundation

// MARK: - File Upload Models
struct CozeFileUploadResponse: Codable {
    let code: Int
    let msg: String
    let data: CozeFileData?
}

struct CozeFileData: Codable {
    let id: String
    let bytes: Int
    let file_name: String
    let created_at: Int
}

// MARK: - Coze API Models
enum WorkflowParameterValue: Codable {
    case string(String)
    case fileId(String)  // 修改为使用file_id而不是原始数据
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .fileId(let fileId):
            // 文件ID直接作为字符串传递，不包装在对象中
            try container.encode(fileId)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self = .string(stringValue)
    }
}

struct CozeWorkflowRequest: Codable {
    let workflow_id: String
    let parameters: [String: WorkflowParameterValue]
    
    // 便利初始化器，用于字符串参数
    init(workflow_id: String, parameters: [String: String]) {
        self.workflow_id = workflow_id
        self.parameters = parameters.mapValues { .string($0) }
    }
    
    // 完整初始化器，支持所有参数类型
    init(workflow_id: String, parameters: [String: WorkflowParameterValue]) {
        self.workflow_id = workflow_id
        self.parameters = parameters
    }
}

struct CozeWorkflowResponse: Codable {
    let code: Int
    let msg: String
    let data: String?  // 修复：data 字段是字符串，不是对象
}

// MARK: - Photo Data Models
struct PhotoData: Codable, Identifiable {
    let id = UUID()
    let url: String
    let date: String
    let tag: String
    let text: String
    
    private enum CodingKeys: String, CodingKey {
        case url, date, tag, text
    }
}

// MARK: - Chat Detail Models
struct ChatDetailData: Codable, Identifiable {
    let id = UUID()
    let question_url: String
    let answer_url: String
    let question: String
    let answer: String
    let date: String
    
    // Computed properties for UI compatibility
    var questionUrl: String { question_url }
    var answerUrl: String { answer_url }
    
    private enum CodingKeys: String, CodingKey {
        case question_url, answer_url, question, answer, date
    }
}

// MARK: - Coze API Service
class CozeAPIService: ObservableObject {
    static let shared = CozeAPIService()
    
    private let apiKey = "pat_Pjxedwpj2yxAzYF2wH3iyJaj66gn5lknFwK1o1UPyIbIFjB0Ap9BEY2d0fljcmMS"
    private let baseURL = "https://api.coze.cn/v1/workflow/run"
    
    // Workflow IDs
    // AI 助手工作流
    private let aiAssistantPhotoWorkflowId = "7530999839682969638"  // AI助手列表
    private let aiAssistantDetailWorkflowId = "7531002456470700074"  // AI助手细节
    
    // 数字孪生工作流
    private let digitalTwinWorkflowId = "7531208234272964651"  // 数字孪生列表&细节
    
    // 测试模式开关
    static var isTestMode = false
    
    init() {}
    
    // MARK: - File Upload Methods
    func uploadFile(data: Data, fileName: String, mimeType: String) async throws -> String {
        print("🚀 开始上传文件: \(fileName)")
        print("📏 文件大小: \(data.count) 字节")
        
        let uploadURL = "https://api.coze.cn/v1/files/upload"
        guard let url = URL(string: uploadURL) else {
            print("❌ 无效的上传 URL: \(uploadURL)")
            throw CozeAPIError.invalidURL
        }
        
        // 创建multipart/form-data请求
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 构建multipart body
        var body = Data()
        
        // 添加文件数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🌐 发送文件上传请求到: \(url)")
        print("🔑 使用 API Key: \(apiKey.prefix(20))...")
        
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP 状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("❌ HTTP 错误: \(httpResponse.statusCode)")
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        print("📄 错误响应内容: \(responseString)")
                    }
                    throw CozeAPIError.networkError
                }
            }
            
            // 打印原始响应
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("📄 上传响应: \(responseString)")
            }
            
            let uploadResponse = try JSONDecoder().decode(CozeFileUploadResponse.self, from: responseData)
            print("✅ 文件上传成功")
            print("📊 响应代码: \(uploadResponse.code)")
            print("💬 响应消息: \(uploadResponse.msg)")
            
            if uploadResponse.code != 0 {
                print("❌ 文件上传失败: \(uploadResponse.msg)")
                throw CozeAPIError.apiError(uploadResponse.msg)
            }
            
            guard let fileData = uploadResponse.data else {
                print("❌ 上传响应中没有文件数据")
                throw CozeAPIError.invalidResponse
            }
            
            print("📁 文件ID: \(fileData.id)")
            print("📝 文件名: \(fileData.file_name)")
            print("📏 文件大小: \(fileData.bytes) 字节")
            
            return fileData.id
            
        } catch {
            print("❌ 文件上传失败: \(error)")
            throw error
        }
    }
    
    // 便利方法：上传图片文件
    func uploadImage(data: Data, fileName: String = "image.jpg") async throws -> String {
        return try await uploadFile(data: data, fileName: fileName, mimeType: "image/jpeg")
    }
    
    // 便利方法：上传音频文件
    func uploadAudio(data: Data, fileName: String = "audio.mp3") async throws -> String {
        return try await uploadFile(data: data, fileName: fileName, mimeType: "audio/mpeg")
    }
    
    // MARK: - Digital Twin Photos by Year
    func getDigitalTwinPhotosByYear(_ year: String) async throws -> [PhotoData] {
        if CozeAPIService.isTestMode {
            return getTestPhotoData()
        }
        
        let request = CozeWorkflowRequest(
            workflow_id: digitalTwinWorkflowId,
            parameters: ["year": year]
        )
        
        let response = try await executeWorkflow(request)
        
        guard let dataString = response.data else {
            print("No data from API, returning mock data")
            return createMockPhotoData()
        }
        
        // 解析 data 字符串中的 output 字段
        if let dataData = dataString.data(using: .utf8) {
            do {
                if let dataObject = try JSONSerialization.jsonObject(with: dataData) as? [String: Any],
                   let outputArray = dataObject["output"] as? [[String: Any]] {
                    
                    var photos: [PhotoData] = []
                    for item in outputArray {
                        if let date = item["date"] as? String,
                           let url = item["url"] as? String,
                           let tag = item["tag"] as? String,
                           let text = item["text"] as? String {
                            photos.append(PhotoData(url: url, date: date, tag: tag, text: text))
                        }
                    }
                    
                    if !photos.isEmpty {
                        print("✅ 成功解析数字孪生照片数据，共 \(photos.count) 张")
                        return photos
                    }
                }
            } catch {
                print("❌ 解析 data 字符串失败: \(error)")
            }
        }
        
        // 打印原始输出以便调试
        print("Raw API data for digital twin photos: \(dataString)")
        
        return parsePhotoData(from: dataString)
    }
    
    // MARK: - AI Assistant Photos by Year
    func getAIAssistantPhotosByYear(_ year: String) async throws -> [PhotoData] {
        if CozeAPIService.isTestMode {
            return getTestPhotoData()
        }
        
        let request = CozeWorkflowRequest(
            workflow_id: aiAssistantPhotoWorkflowId,
            parameters: ["year": year]
        )
        
        let response = try await executeWorkflow(request)
        
        guard let dataString = response.data else {
            print("No data from API, returning mock data")
            return createMockPhotoData()
        }
        
        // AI助手的输出格式只包含 url 和 date
        if let dataData = dataString.data(using: .utf8) {
            do {
                if let dataObject = try JSONSerialization.jsonObject(with: dataData) as? [String: Any],
                   let outputArray = dataObject["output"] as? [[String: Any]] {
                    
                    var photos: [PhotoData] = []
                    for item in outputArray {
                        if let date = item["date"] as? String,
                           let url = item["url"] as? String {
                            // AI助手只有 url 和 date，tag 和 text 设为空
                            photos.append(PhotoData(url: url, date: date, tag: "", text: ""))
                        }
                    }
                    
                    if !photos.isEmpty {
                        print("✅ 成功解析AI助手照片数据，共 \(photos.count) 张")
                        return photos
                    }
                }
            } catch {
                print("❌ 解析 data 字符串失败: \(error)")
            }
        }
        
        // 打印原始输出以便调试
        print("Raw API data for AI assistant photos: \(dataString)")
        
        return parseAIAssistantPhotoData(from: dataString)
    }
    
    // MARK: - Get Chat Details by Image URL
    func getChatDetails(for imageURL: String) async throws -> [ChatDetailData] {
        if CozeAPIService.isTestMode {
            return getTestChatDetailData()
        }
        
        let request = CozeWorkflowRequest(
            workflow_id: aiAssistantDetailWorkflowId,
            parameters: ["input_pic": imageURL]
        )
        
        let response = try await executeWorkflow(request)
        
        guard let dataString = response.data else {
            print("No data from API, returning mock data")
            return createMockChatDetailData()
        }
        
        // 打印原始输出以便调试
        print("Raw API data for chat details: \(dataString)")
        
        return parseChatDetailData(from: dataString)
    }
    
    // MARK: - Private Parsing Methods
    private func parsePhotoData(from outputString: String) -> [PhotoData] {
        print("🔍 开始解析照片数据...")
        print("📄 原始输出: \(outputString)")
        
        // 1. 尝试直接解析为 JSON 数组
        if let data = outputString.data(using: .utf8) {
            do {
                let photos = try JSONDecoder().decode([PhotoData].self, from: data)
                print("✅ 成功解析为 JSON 数组")
                return photos
            } catch {
                print("❌ JSON 数组解析失败: \(error)")
            }
            
            // 2. 尝试解析为新的工作流格式 (包含 date, tag, text, url 字段)
            struct WorkflowPhotoItem: Codable {
                let date: String
                let url: String
                let tag: String
                let text: String
            }
            
            do {
                let workflowItems = try JSONDecoder().decode([WorkflowPhotoItem].self, from: data)
                let photos = workflowItems.map { item in
                    PhotoData(url: item.url, date: item.date, tag: item.tag, text: item.text)
                }
                print("✅ 成功解析为工作流格式")
                return photos
            } catch {
                print("❌ 工作流格式解析失败: \(error)")
            }
            
            // 3. 尝试解析为单个 JSON 对象
            do {
                let photo = try JSONDecoder().decode(PhotoData.self, from: data)
                print("✅ 成功解析为单个 JSON 对象")
                return [photo]
            } catch {
                print("❌ 单个对象解析失败: \(error)")
            }
            
            // 4. 尝试解析为单个工作流格式对象
            do {
                let workflowItem = try JSONDecoder().decode(WorkflowPhotoItem.self, from: data)
                let photo = PhotoData(url: workflowItem.url, date: workflowItem.date, tag: workflowItem.tag, text: workflowItem.text)
                print("✅ 成功解析为单个工作流格式对象")
                return [photo]
            } catch {
                print("❌ 单个工作流格式解析失败: \(error)")
            }
            
            // 5. 尝试解析为包装对象
            struct WrappedResponse: Codable {
                let photos: [PhotoData]?
                let data: [PhotoData]?
                let items: [PhotoData]?
                let results: [PhotoData]?
                let output: [WorkflowPhotoItem]?
            }
            
            do {
                let wrapped = try JSONDecoder().decode(WrappedResponse.self, from: data)
                if let photos = wrapped.photos ?? wrapped.data ?? wrapped.items ?? wrapped.results {
                    print("✅ 成功解析为包装对象")
                    return photos
                } else if let workflowItems = wrapped.output {
                    let photos = workflowItems.map { item in
                        PhotoData(url: item.url, date: item.date, tag: item.tag, text: item.text)
                    }
                    print("✅ 成功解析为包装的工作流格式")
                    return photos
                }
            } catch {
                print("❌ 包装对象解析失败: \(error)")
            }
            
            // 6. 尝试解析为字符串格式的 JSON
            if let jsonString = try? JSONSerialization.jsonObject(with: data) as? String,
               let innerData = jsonString.data(using: .utf8) {
                do {
                    let photos = try JSONDecoder().decode([PhotoData].self, from: innerData)
                    print("✅ 成功解析嵌套 JSON 字符串")
                    return photos
                } catch {
                    print("❌ 嵌套 JSON 字符串解析失败: \(error)")
                }
                
                // 尝试解析嵌套的工作流格式
                do {
                    let workflowItems = try JSONDecoder().decode([WorkflowPhotoItem].self, from: innerData)
                    let photos = workflowItems.map { item in
                        PhotoData(url: item.url, date: item.date, tag: item.tag, text: item.text)
                    }
                    print("✅ 成功解析嵌套工作流格式")
                    return photos
                } catch {
                    print("❌ 嵌套工作流格式解析失败: \(error)")
                }
            }
        }
        
        // 7. 尝试手动解析文本格式
        let manuallyParsed = parsePhotoDataManually(from: outputString)
        if !manuallyParsed.isEmpty {
            print("✅ 手动解析成功")
            return manuallyParsed
        }
        
        // 8. 如果所有方法都失败，返回模拟数据
        print("❌ 所有解析方法都失败，返回模拟数据")
        return createMockPhotoData()
    }
    
    private func parseAIAssistantPhotoData(from outputString: String) -> [PhotoData] {
        print("🔍 开始解析AI助手照片数据...")
        print("📄 原始输出: \(outputString)")
        
        // AI助手的数据格式只包含 url 和 date
        if let data = outputString.data(using: .utf8) {
            // 1. 尝试直接解析为简单的 AI 助手格式
            struct AIAssistantPhotoItem: Codable {
                let date: String
                let url: String
            }
            
            do {
                let aiItems = try JSONDecoder().decode([AIAssistantPhotoItem].self, from: data)
                let photos = aiItems.map { item in
                    PhotoData(url: item.url, date: item.date, tag: "", text: "")
                }
                print("✅ 成功解析为AI助手格式")
                return photos
            } catch {
                print("❌ AI助手格式解析失败: \(error)")
            }
            
            // 2. 尝试解析为单个 AI 助手对象
            do {
                let aiItem = try JSONDecoder().decode(AIAssistantPhotoItem.self, from: data)
                let photo = PhotoData(url: aiItem.url, date: aiItem.date, tag: "", text: "")
                print("✅ 成功解析为单个AI助手对象")
                return [photo]
            } catch {
                print("❌ 单个AI助手对象解析失败: \(error)")
            }
            
            // 3. 尝试解析为包装的 AI 助手格式
            struct WrappedAIResponse: Codable {
                let photos: [AIAssistantPhotoItem]?
                let data: [AIAssistantPhotoItem]?
                let items: [AIAssistantPhotoItem]?
                let results: [AIAssistantPhotoItem]?
                let output: [AIAssistantPhotoItem]?
            }
            
            do {
                let wrapped = try JSONDecoder().decode(WrappedAIResponse.self, from: data)
                if let aiItems = wrapped.photos ?? wrapped.data ?? wrapped.items ?? wrapped.results ?? wrapped.output {
                    let photos = aiItems.map { item in
                        PhotoData(url: item.url, date: item.date, tag: "", text: "")
                    }
                    print("✅ 成功解析为包装的AI助手格式")
                    return photos
                }
            } catch {
                print("❌ 包装AI助手格式解析失败: \(error)")
            }
        }
        
        // 4. 尝试手动解析 AI 助手文本格式
        let manuallyParsed = parseAIAssistantPhotoDataManually(from: outputString)
        if !manuallyParsed.isEmpty {
            print("✅ AI助手手动解析成功")
            return manuallyParsed
        }
        
        // 5. 如果所有方法都失败，返回模拟数据
        print("❌ 所有AI助手解析方法都失败，返回模拟数据")
        return createMockPhotoData()
    }
    
    private func parseChatDetailData(from outputString: String) -> [ChatDetailData] {
        // 尝试多种解析方式
        
        // 1. 尝试直接解析为 JSON 数组
        if let data = outputString.data(using: .utf8) {
            do {
                let details = try JSONDecoder().decode([ChatDetailData].self, from: data)
                print("Successfully parsed as JSON array")
                return details
            } catch {
                print("Failed to parse as JSON array: \(error)")
            }
            
            // 2. 尝试解析为单个 JSON 对象
            do {
                let detail = try JSONDecoder().decode(ChatDetailData.self, from: data)
                print("Successfully parsed as single JSON object")
                return [detail]
            } catch {
                print("Failed to parse as single JSON object: \(error)")
            }
            
            // 3. 尝试解析为包含数组的对象
            if let wrapper = try? JSONDecoder().decode([String: [ChatDetailData]].self, from: data),
               let details = wrapper.values.first {
                print("Successfully parsed as wrapped array")
                return details
            }
            
            // 4. 尝试解析为字符串格式的 JSON
            if let jsonString = try? JSONSerialization.jsonObject(with: data) as? String,
               let innerData = jsonString.data(using: .utf8) {
                do {
                    let details = try JSONDecoder().decode([ChatDetailData].self, from: innerData)
                    print("Successfully parsed nested JSON string")
                    return details
                } catch {
                    print("Failed to parse nested JSON string: \(error)")
                }
            }
        }
        
        // 5. 尝试手动解析文本格式
        let manuallyParsed = parseChatDetailDataManually(from: outputString)
        if !manuallyParsed.isEmpty {
            print("Successfully parsed manually")
            return manuallyParsed
        }
        
        // 6. 如果所有方法都失败，返回模拟数据
        print("All parsing methods failed, returning mock data")
        return createMockChatDetailData()
    }
    
    private func parsePhotoDataManually(from text: String) -> [PhotoData] {
        var photos: [PhotoData] = []
        
        print("🔧 开始手动解析...")
        print("📄 输入文本: \(text)")
        
        // 尝试从文本中提取 URL 和日期
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("http") {
                // 提取 URL
                var extractedURL: String?
                var extractedDate: String?
                
                // 方法1: 寻找完整的 URL (可能包含在引号中)
                let urlPattern = #"https?://[^\s"'\]]+\.(jpg|jpeg|png|gif|webp|bmp)"#
                if let urlRange = line.range(of: urlPattern, options: .regularExpression) {
                    extractedURL = String(line[urlRange])
                }
                
                // 方法2: 如果没找到，尝试更宽松的匹配
                if extractedURL == nil {
                    let components = line.components(separatedBy: " ")
                    for component in components {
                        let cleanComponent = component.trimmingCharacters(in: CharacterSet(charactersIn: "\"'`[]{}()"))
                        if cleanComponent.hasPrefix("http") && (cleanComponent.contains(".jpg") || cleanComponent.contains(".jpeg") || cleanComponent.contains(".png") || cleanComponent.contains(".gif") || cleanComponent.contains(".webp")) {
                            extractedURL = cleanComponent
                            break
                        }
                    }
                }
                
                // 提取日期
                extractedDate = extractDateFromText(line)
                
                // 如果找到了 URL，创建 PhotoData
                if let url = extractedURL {
                    let photo = PhotoData(
                        url: url,
                        date: extractedDate ?? "2024-01-01",
                        tag: "",
                        text: ""
                    )
                    photos.append(photo)
                    print("✅ 手动提取到照片: URL=\(url), Date=\(photo.date)")
                }
            }
        }
        
        // 尝试解析 JSON 片段
        if photos.isEmpty {
            // 寻找类似 {"date":"2024/04/10","url":"..."} 的模式
            let jsonPattern = #"\{[^}]*"date"[^}]*"url"[^}]*\}"#
            let matches = text.matches(of: try! Regex(jsonPattern))
            
            for match in matches {
                let jsonString = String(text[match.range])
                if let data = jsonString.data(using: .utf8) {
                    do {
                        struct TempPhotoItem: Codable {
                            let date: String
                            let url: String
                        }
                        let item = try JSONDecoder().decode(TempPhotoItem.self, from: data)
                        let photo = PhotoData(url: item.url, date: item.date, tag: "", text: "")
                        photos.append(photo)
                        print("✅ 从 JSON 片段提取到照片: \(photo)")
                    } catch {
                        print("❌ JSON 片段解析失败: \(error)")
                    }
                }
            }
        }
        
        print("🔧 手动解析完成，共找到 \(photos.count) 张照片")
        return photos
    }
    
    private func parseChatDetailDataManually(from text: String) -> [ChatDetailData] {
        // 简单的手动解析逻辑
        // 这里可以根据实际的文本格式进行调整
        return []
    }
    
    private func parseAIAssistantPhotoDataManually(from text: String) -> [PhotoData] {
        var photos: [PhotoData] = []
        
        print("🔧 开始手动解析AI助手照片数据...")
        print("📄 输入文本: \(text)")
        
        // AI助手只需要解析 url 和 date 字段
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("http") {
                // 提取 URL
                var extractedURL: String?
                var extractedDate: String?
                
                // 寻找 URL
                let urlPattern = #"https?://[^\s"'\]]+\.(jpg|jpeg|png|gif|webp|bmp)"#
                if let urlRange = line.range(of: urlPattern, options: .regularExpression) {
                    extractedURL = String(line[urlRange])
                }
                
                // 如果没找到，尝试更宽松的匹配
                if extractedURL == nil {
                    let components = line.components(separatedBy: " ")
                    for component in components {
                        let cleanComponent = component.trimmingCharacters(in: CharacterSet(charactersIn: "\"'`[]{}()"))
                        if cleanComponent.hasPrefix("http") && (cleanComponent.contains(".jpg") || cleanComponent.contains(".jpeg") || cleanComponent.contains(".png") || cleanComponent.contains(".gif") || cleanComponent.contains(".webp")) {
                            extractedURL = cleanComponent
                            break
                        }
                    }
                }
                
                // 提取日期
                extractedDate = extractDateFromText(line)
                
                // 如果找到了 URL，创建 PhotoData（AI助手格式：只有 url 和 date）
                if let url = extractedURL {
                    let photo = PhotoData(
                        url: url,
                        date: extractedDate ?? "2025-01-01",
                        tag: "",  // AI助手没有 tag
                        text: ""  // AI助手没有 text
                    )
                    photos.append(photo)
                    print("✅ 手动提取到AI助手照片: URL=\(url), Date=\(photo.date)")
                }
            }
        }
        
        // 尝试解析 AI 助手的 JSON 片段（只包含 date 和 url）
        if photos.isEmpty {
            let jsonPattern = #"\{[^}]*"date"[^}]*"url"[^}]*\}"#
            let matches = text.matches(of: try! Regex(jsonPattern))
            
            for match in matches {
                let jsonString = String(text[match.range])
                if let data = jsonString.data(using: .utf8) {
                    do {
                        struct TempAIPhotoItem: Codable {
                            let date: String
                            let url: String
                        }
                        let item = try JSONDecoder().decode(TempAIPhotoItem.self, from: data)
                        let photo = PhotoData(url: item.url, date: item.date, tag: "", text: "")
                        photos.append(photo)
                        print("✅ 从AI助手JSON片段提取到照片: \(photo)")
                    } catch {
                        print("❌ AI助手JSON片段解析失败: \(error)")
                    }
                }
            }
        }
        
        print("🔧 AI助手手动解析完成，共找到 \(photos.count) 张照片")
        return photos
    }
    
    private func extractDateFromText(_ text: String) -> String? {
        // 尝试从文本中提取日期，支持多种格式
        
        // 格式1: 2024/04/10
        let datePattern1 = #"\d{4}/\d{2}/\d{2}"#
        if let range = text.range(of: datePattern1, options: .regularExpression) {
            let dateString = String(text[range])
            // 转换为标准格式 2024-04-10
            return dateString.replacingOccurrences(of: "/", with: "-")
        }
        
        // 格式2: 2024-04-10
        let datePattern2 = #"\d{4}-\d{2}-\d{2}"#
        if let range = text.range(of: datePattern2, options: .regularExpression) {
            return String(text[range])
        }
        
        // 格式3: 2024.04.10
        let datePattern3 = #"\d{4}\.\d{2}\.\d{2}"#
        if let range = text.range(of: datePattern3, options: .regularExpression) {
            let dateString = String(text[range])
            return dateString.replacingOccurrences(of: ".", with: "-")
        }
        
        // 格式4: 04/10/2024
        let datePattern4 = #"\d{2}/\d{2}/\d{4}"#
        if let range = text.range(of: datePattern4, options: .regularExpression) {
            let dateString = String(text[range])
            let components = dateString.components(separatedBy: "/")
            if components.count == 3 {
                return "\(components[2])-\(components[0])-\(components[1])"
            }
        }
        
        return nil
    }
    
    private func createMockPhotoData() -> [PhotoData] {
        return [
            PhotoData(url: "https://example.com/photo1.jpg", date: "2024-01-01", tag: "家庭", text: "温馨的家庭聚会时光"),
            PhotoData(url: "https://example.com/photo2.jpg", date: "2024-01-02", tag: "风景", text: "美丽的日落景色"),
            PhotoData(url: "https://example.com/photo3.jpg", date: "2024-01-03", tag: "生活", text: "日常生活的美好瞬间")
        ]
    }
    
    private func createMockChatDetailData() -> [ChatDetailData] {
        return [
            ChatDetailData(
                question_url: "https://example.com/question.mp3",
                answer_url: "https://example.com/answer.mp3",
                question: "这是什么？",
                answer: "这是一个示例回答，展示了 AI 助手的功能。",
                date: "2024-01-01"
            )
        ]
    }
    
    // MARK: - Test Data Methods
    private func getTestPhotoData() -> [PhotoData] {
        print("🧪 [测试模式] 返回模拟照片数据")
        return [
            PhotoData(url: "https://picsum.photos/300/200?random=1", date: "2024-01-15", tag: "自然", text: "春天的花园景色"),
            PhotoData(url: "https://picsum.photos/300/200?random=2", date: "2024-02-20", tag: "建筑", text: "现代城市建筑"),
            PhotoData(url: "https://picsum.photos/300/200?random=3", date: "2024-03-10", tag: "人物", text: "朋友聚会合影"),
            PhotoData(url: "https://picsum.photos/300/200?random=4", date: "2024-04-05", tag: "动物", text: "可爱的小猫咪"),
            PhotoData(url: "https://picsum.photos/300/200?random=5", date: "2024-05-12", tag: "食物", text: "美味的晚餐"),
            PhotoData(url: "https://picsum.photos/300/200?random=6", date: "2024-06-18", tag: "旅行", text: "海边度假风光")
        ]
    }
    
    private func getTestChatDetailData() -> [ChatDetailData] {
        print("🧪 [测试模式] 返回模拟聊天详情数据")
        return [
            ChatDetailData(
                question_url: "https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3",
                answer_url: "https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3",
                question: "这张照片是在哪里拍的？",
                answer: "这张照片看起来是在一个美丽的公园里拍摄的。从背景可以看到绿色的草地和一些树木，光线很好，应该是在下午时分拍摄的。",
                date: "2024-01-15"
            ),
            ChatDetailData(
                question_url: "https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3",
                answer_url: "https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3",
                question: "照片中的人是谁？",
                answer: "我可以看到照片中有一个人，但出于隐私保护，我不会识别具体的个人身份。我可以描述他们的服装或姿势等一般特征。",
                date: "2024-01-15"
            )
        ]
    }
    
    // MARK: - Get Single Chat Detail by Image URL
    func getChatDetail(imageUrl: String) async throws -> ChatDetailData {
        let details = try await getChatDetails(for: imageUrl)
        guard let firstDetail = details.first else {
            throw CozeAPIError.invalidResponse
        }
        return firstDetail
    }
    
    // MARK: - Private Methods
    func executeWorkflow(_ request: CozeWorkflowRequest) async throws -> CozeWorkflowResponse {
        print("🚀 开始执行工作流...")
        print("📋 工作流 ID: \(request.workflow_id)")
        print("📝 参数: \(request.parameters)")
        
        // 构建完整的工作流执行 URL
        let workflowURL = "https://api.coze.cn/v1/workflow/run"
        guard let url = URL(string: workflowURL) else {
            print("❌ 无效的 URL: \(workflowURL)")
            throw CozeAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        // 打印详细的请求信息
        print("🌐 发送请求到: \(url)")
        print("🔑 使用 API Key: \(apiKey.prefix(20))...")
        
        // 打印请求体内容
        if let requestString = String(data: requestData, encoding: .utf8) {
            print("📤 请求体: \(requestString)")
        }
        
        // 打印请求头
        print("📋 请求头:")
        for (key, value) in urlRequest.allHTTPHeaderFields ?? [:] {
            print("  \(key): \(value)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP 状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("❌ HTTP 错误: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 错误响应内容: \(responseString)")
                    }
                    throw CozeAPIError.networkError
                }
            }
            
            // 打印原始响应
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 原始响应: \(responseString)")
            }
            
            let cozeResponse = try JSONDecoder().decode(CozeWorkflowResponse.self, from: data)
            print("✅ 成功解析响应")
            print("📊 响应代码: \(cozeResponse.code)")
            print("💬 响应消息: \(cozeResponse.msg)")
            
            if cozeResponse.code != 0 {
                print("❌ API 返回错误: \(cozeResponse.msg)")
                throw CozeAPIError.apiError(cozeResponse.msg)
            }
            
            if let dataString = cozeResponse.data {
                print("📤 工作流数据: \(dataString)")
            } else {
                print("⚠️ 工作流没有数据")
            }
            
            return cozeResponse
            
        } catch {
            print("❌ 请求失败: \(error)")
            throw error
        }
    }
}

// MARK: - Error Types
enum CozeAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应数据"
        case .networkError:
            return "网络请求失败"
        case .apiError(let message):
            return "API 错误: \(message)"
        }
    }
}