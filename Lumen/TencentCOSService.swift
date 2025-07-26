import Foundation
import UIKit
import CommonCrypto
import SystemConfiguration

// MARK: - 腾讯云COS服务类
class TencentCOSService {
    
    // MARK: - 配置信息
    private static let bucket = "img-audio-buffer-1343897345" // 您的COS存储桶名称
    private static let region = "ap-guangzhou" // 您的COS区域
    private static let cosBaseURL = "https://\(bucket).cos.\(region).myqcloud.com"
    
    // 方案1: 直接配置永久密钥（不推荐用于生产环境）
    private static let secretId = "YOUR_SECRET_ID" // 替换为您的SecretId
    private static let secretKey = "YOUR_SECRET_KEY" // 替换为您的SecretKey
    
    // 方案2: 后端服务器地址（用于获取临时密钥或预签名URL）
    private static let serverURL = "https://your-backend-server.com" // 替换为您的后端服务器地址
    
    // MARK: - 单例
    static let shared = TencentCOSService()
    private init() {}
    
    // MARK: - 分块上传方法（适用于大文件）
    static func uploadLargeFile(data: Data, fileName: String, chunkSize: Int = 5 * 1024 * 1024) async throws -> String {
        print("📦 开始分块上传大文件: \(fileName)")
        print("📊 文件总大小: \(data.count) bytes")
        print("🔢 分块大小: \(chunkSize) bytes")
        
        let contentType = getContentType(for: fileName)
        
        // 如果文件小于分块大小，直接使用普通上传
        if data.count <= chunkSize {
            print("📤 文件较小，使用普通上传")
            return try await uploadFileWithPermanentKey(data: data, fileName: fileName, contentType: contentType)
        }
        
        // 计算分块数量
        let totalChunks = (data.count + chunkSize - 1) / chunkSize
        print("🧩 总分块数: \(totalChunks)")
        
        // 1. 初始化分块上传
        let uploadId = try await initiateMultipartUpload(fileName: fileName, contentType: contentType)
        print("🆔 上传ID: \(uploadId)")
        
        var uploadedParts: [(partNumber: Int, etag: String)] = []
        
        // 2. 上传各个分块
        for chunkIndex in 0..<totalChunks {
            let startIndex = chunkIndex * chunkSize
            let endIndex = min(startIndex + chunkSize, data.count)
            let chunkData = data.subdata(in: startIndex..<endIndex)
            let partNumber = chunkIndex + 1
            
            print("📤 上传分块 \(partNumber)/\(totalChunks), 大小: \(chunkData.count) bytes")
            
            let etag = try await uploadPart(
                data: chunkData,
                fileName: fileName,
                uploadId: uploadId,
                partNumber: partNumber
            )
            
            uploadedParts.append((partNumber: partNumber, etag: etag))
            print("✅ 分块 \(partNumber) 上传成功, ETag: \(etag)")
        }
        
        // 3. 完成分块上传
        let finalURL = try await completeMultipartUpload(
            fileName: fileName,
            uploadId: uploadId,
            parts: uploadedParts
        )
        
        print("🎉 分块上传完成: \(finalURL)")
        return finalURL
    }
    
    // MARK: - 初始化分块上传
    private static func initiateMultipartUpload(fileName: String, contentType: String) async throws -> String {
        let uploadURL = "\(cosBaseURL)/\(fileName)?uploads"
        let host = "\(bucket).cos.\(region).myqcloud.com"
        
        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "Host")
        
        // 生成认证签名
        let authorization = generateCOSAuthorizationWithPermanentKey(
            method: "POST",
            uri: "/\(fileName)?uploads",
            contentType: contentType,
            host: host
        )
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TencentCOSError.uploadFailed("初始化分块上传失败")
        }
        
        // 解析响应获取UploadId
        guard let responseString = String(data: responseData, encoding: .utf8),
              let uploadId = extractUploadId(from: responseString) else {
            throw TencentCOSError.uploadFailed("无法获取UploadId")
        }
        
        return uploadId
    }
    
    // MARK: - 上传单个分块
    private static func uploadPart(data: Data, fileName: String, uploadId: String, partNumber: Int) async throws -> String {
        let uploadURL = "\(cosBaseURL)/\(fileName)?partNumber=\(partNumber)&uploadId=\(uploadId)"
        let host = "\(bucket).cos.\(region).myqcloud.com"
        
        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        request.setValue(host, forHTTPHeaderField: "Host")
        
        // 生成认证签名
        let authorization = generateCOSAuthorizationWithPermanentKey(
            method: "PUT",
            uri: "/\(fileName)?partNumber=\(partNumber)&uploadId=\(uploadId)",
            contentType: "application/octet-stream",
            host: host
        )
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let etag = httpResponse.allHeaderFields["ETag"] as? String else {
            throw TencentCOSError.uploadFailed("分块 \(partNumber) 上传失败")
        }
        
        return etag.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    // MARK: - 完成分块上传
    private static func completeMultipartUpload(fileName: String, uploadId: String, parts: [(partNumber: Int, etag: String)]) async throws -> String {
        let uploadURL = "\(cosBaseURL)/\(fileName)?uploadId=\(uploadId)"
        let host = "\(bucket).cos.\(region).myqcloud.com"
        
        // 构建完成上传的XML
        var xmlBody = "<CompleteMultipartUpload>"
        for part in parts.sorted(by: { $0.partNumber < $1.partNumber }) {
            xmlBody += "<Part><PartNumber>\(part.partNumber)</PartNumber><ETag>\(part.etag)</ETag></Part>"
        }
        xmlBody += "</CompleteMultipartUpload>"
        
        let bodyData = xmlBody.data(using: .utf8)!
        
        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(String(bodyData.count), forHTTPHeaderField: "Content-Length")
        request.setValue(host, forHTTPHeaderField: "Host")
        
        // 生成认证签名
        let authorization = generateCOSAuthorizationWithPermanentKey(
            method: "POST",
            uri: "/\(fileName)?uploadId=\(uploadId)",
            contentType: "application/xml",
            host: host
        )
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TencentCOSError.uploadFailed("完成分块上传失败")
        }
        
        return "\(cosBaseURL)/\(fileName)"
    }
    
    // MARK: - 从XML响应中提取UploadId
    private static func extractUploadId(from xmlString: String) -> String? {
        let pattern = "<UploadId>(.*?)</UploadId>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: xmlString.utf16.count)
        
        if let match = regex?.firstMatch(in: xmlString, options: [], range: range) {
            let uploadIdRange = Range(match.range(at: 1), in: xmlString)
            return uploadIdRange.map { String(xmlString[$0]) }
        }
        
        return nil
    }

    // MARK: - 智能上传方法（自动选择上传策略）
    static func smartUpload(data: Data, fileName: String) async throws -> String {
        print("🧠 智能上传开始，文件: \(fileName), 大小: \(data.count) bytes")
        
        // 设置阈值：100MB以上使用分块上传
        let multipartThreshold = 100 * 1024 * 1024 // 100MB
        
        if data.count > multipartThreshold {
            print("📦 文件较大(\(data.count) bytes > \(multipartThreshold) bytes)，使用分块上传")
            return try await uploadLargeFile(data: data, fileName: fileName)
        } else {
            print("📤 文件较小(\(data.count) bytes <= \(multipartThreshold) bytes)，使用普通上传")
            return try await uploadFile(data: data, fileName: fileName)
        }
    }

    // MARK: - 通用上传方法（自动检测Content-Type）
    static func uploadFile(data: Data, fileName: String) async throws -> String {
        let contentType = getContentType(for: fileName)
        return try await uploadFileWithPermanentKey(data: data, fileName: fileName, contentType: contentType)
    }
    
    // MARK: - 根据文件扩展名获取Content-Type
    private static func getContentType(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        // 图片类型
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "bmp":
            return "image/bmp"
        case "svg":
            return "image/svg+xml"
        case "ico":
            return "image/x-icon"
        case "tiff", "tif":
            return "image/tiff"
        
        // 音频类型
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "aac":
            return "audio/aac"
        case "ogg":
            return "audio/ogg"
        case "flac":
            return "audio/flac"
        case "m4a":
            return "audio/mp4"
        case "wma":
            return "audio/x-ms-wma"
        
        // 视频类型
        case "mp4":
            return "video/mp4"
        case "avi":
            return "video/x-msvideo"
        case "mov":
            return "video/quicktime"
        case "wmv":
            return "video/x-ms-wmv"
        case "flv":
            return "video/x-flv"
        case "webm":
            return "video/webm"
        case "mkv":
            return "video/x-matroska"
        
        // 文档类型
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt":
            return "application/vnd.ms-powerpoint"
        case "pptx":
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "txt":
            return "text/plain"
        case "rtf":
            return "application/rtf"
        
        // 压缩文件
        case "zip":
            return "application/zip"
        case "rar":
            return "application/vnd.rar"
        case "7z":
            return "application/x-7z-compressed"
        case "tar":
            return "application/x-tar"
        case "gz":
            return "application/gzip"
        
        // 代码文件
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        case "swift":
            return "text/x-swift"
        case "py":
            return "text/x-python"
        case "java":
            return "text/x-java-source"
        case "cpp", "cc", "cxx":
            return "text/x-c++src"
        case "c":
            return "text/x-csrc"
        case "h":
            return "text/x-chdr"
        
        // 默认类型
        default:
            return "application/octet-stream"
        }
    }

    // MARK: - 通用上传方法（使用永久密钥）
    static func uploadFileWithPermanentKey(data: Data, fileName: String, contentType: String) async throws -> String {
        print("📤 开始上传文件到腾讯云COS: \(fileName)")
        print("📊 文件大小: \(data.count) bytes")
        print("📋 Content-Type: \(contentType)")
        
        // 检查密钥配置
        guard secretId != "YOUR_SECRET_ID" && secretKey != "YOUR_SECRET_KEY" else {
            throw TencentCOSError.credentialsError("请先配置您的SecretId和SecretKey")
        }
        
        // 检查文件大小限制（5GB）
        let maxFileSize = 5 * 1024 * 1024 * 1024 // 5GB
        guard data.count <= maxFileSize else {
            throw TencentCOSError.uploadFailed("文件大小超过5GB限制，请使用分块上传")
        }
        
        // 构建上传URL
        let uploadURL = "\(cosBaseURL)/\(fileName)"
        let host = "\(bucket).cos.\(region).myqcloud.com"
        
        // 创建请求
        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        request.setValue(host, forHTTPHeaderField: "Host")
        
        // 生成认证签名
        let authorization = generateCOSAuthorizationWithPermanentKey(
            method: "PUT",
            uri: "/\(fileName)",
            contentType: contentType,
            host: host
        )
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        print("🔐 生成的签名: \(authorization)")
        print("🌐 上传URL: \(uploadURL)")
        
        // 发送请求
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TencentCOSError.uploadFailed("无效的响应")
            }
            
            print("📡 响应状态码: \(httpResponse.statusCode)")
            if let responseHeaders = httpResponse.allHeaderFields as? [String: String] {
                print("📋 响应头部: \(responseHeaders)")
            }
            
            // 打印响应内容（用于调试）
            if !responseData.isEmpty {
                let responseString = String(data: responseData, encoding: .utf8) ?? "无法解析响应内容"
                print("📄 响应内容: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "上传失败，状态码: \(httpResponse.statusCode)"
                if !responseData.isEmpty {
                    let responseString = String(data: responseData, encoding: .utf8) ?? ""
                    throw TencentCOSError.uploadFailed("\(errorMessage), 错误详情: \(responseString)")
                } else {
                    throw TencentCOSError.uploadFailed(errorMessage)
                }
            }
            
            print("✅ 文件上传成功: \(uploadURL)")
            return uploadURL
            
        } catch let error as TencentCOSError {
            throw error
        } catch {
            print("❌ 网络请求失败: \(error)")
            throw TencentCOSError.networkError("网络请求失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 上传图片到腾讯云COS（智能上传）
    static func uploadImageWithPermanentKey(data: Data, fileName: String) async throws -> String {
        print("🖼️ 开始上传图片: \(fileName)")
        return try await smartUpload(data: data, fileName: fileName)
    }

    // MARK: - 上传音频到腾讯云COS（智能上传）
    static func uploadAudioWithPermanentKey(data: Data, fileName: String) async throws -> String {
        print("🎵 开始上传音频: \(fileName)")
        return try await smartUpload(data: data, fileName: fileName)
    }
    
    // MARK: - 工具方法
    
    /// 格式化文件大小
    static func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// 验证文件名是否合法
    static func isValidFileName(_ fileName: String) -> Bool {
        // 检查文件名长度
        guard fileName.count > 0 && fileName.count <= 255 else {
            return false
        }
        
        // 检查是否包含非法字符
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return fileName.rangeOfCharacter(from: invalidCharacters) == nil
    }
    
    /// 生成唯一文件名
    static func generateUniqueFileName(originalName: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        let fileExtension = (originalName as NSString).pathExtension
        let baseName = (originalName as NSString).deletingPathExtension
        
        if fileExtension.isEmpty {
            return "\(baseName)_\(timestamp)_\(uuid)"
        } else {
            return "\(baseName)_\(timestamp)_\(uuid).\(fileExtension)"
        }
    }
    
    /// 检查网络连接状态
    static func checkNetworkConnection() -> Bool {
        // 简单的网络检查，实际项目中可以使用更复杂的网络检测库
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }

    // MARK: - 获取临时密钥
    private static func getTemporaryCredentials() async throws -> TencentCOSCredentials {
        print("🔑 正在获取临时密钥...")
        
        guard let url = URL(string: "\(serverURL)/getKeyAndCredentials") else {
            throw TencentCOSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 获取密钥响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    throw TencentCOSError.networkError("获取密钥失败")
                }
            }
            
            // 解析响应
            let credentials = try JSONDecoder().decode(TencentCOSCredentials.self, from: data)
            return credentials
            
        } catch {
            print("❌ 获取临时密钥失败: \(error)")
            throw TencentCOSError.credentialsError("获取临时密钥失败")
        }
    }
    
    // MARK: - 生成COS认证签名（使用永久密钥）
    private static func generateCOSAuthorizationWithPermanentKey(
        method: String,
        uri: String,
        contentType: String,
        host: String
    ) -> String {
        let now = Int(Date().timeIntervalSince1970)
        let keyTime = "\(now);\(now + 3600)"
        let signedHeaders = "content-type;host"
        
        // 解析URI和查询参数
        let components = uri.components(separatedBy: "?")
        let path = components[0]
        let queryString = components.count > 1 ? components[1] : ""
        
        // 处理查询参数
        var urlParamList = ""
        var urlParams = ""
        
        if !queryString.isEmpty {
            let params = queryString.components(separatedBy: "&")
                .map { param in
                    let keyValue = param.components(separatedBy: "=")
                    let key = keyValue[0]
                    let value = keyValue.count > 1 ? keyValue[1] : ""
                    return (key: key, value: value)
                }
                .sorted { $0.key < $1.key }
            
            urlParamList = params.map { $0.key }.joined(separator: ";")
            urlParams = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        }
        
        // 1. 生成 SignKey
        let signKey = hmacSHA1(key: secretKey, data: keyTime)
        
        // 2. 构建 HttpString
        // 对Content-Type进行URL编码，确保斜杠被编码为%2F
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "/") // 确保斜杠被编码
        let encodedContentType = contentType.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? contentType
        
        // 构建头部字符串，按照腾讯云规范：content-type=xxx&host=xxx
        // 注意：这里必须使用编码后的Content-Type
        let headerString = "content-type=\(encodedContentType)&host=\(host)"
        
        // HttpString格式：method\npath\nquery_params\nheader_params\n
        let httpString = "\(method.lowercased())\n\(path)\n\(urlParams)\n\(headerString)\n"
        
        print("🔍 HttpString: \(httpString)")
        
        // 3. 生成 StringToSign
        let httpStringHash = sha1(data: httpString)
        let stringToSign = "sha1\n\(keyTime)\n\(httpStringHash)\n"
        
        print("🔍 StringToSign: \(stringToSign)")
        
        // 4. 生成 Signature
        let signature = hmacSHA1(key: signKey, data: stringToSign)
        
        let authorization = "q-sign-algorithm=sha1&q-ak=\(secretId)&q-sign-time=\(keyTime)&q-key-time=\(keyTime)&q-header-list=\(signedHeaders)&q-url-param-list=\(urlParamList)&q-signature=\(signature)"
        
        print("🔍 最终签名: \(authorization)")
        
        return authorization
    }
    
    // MARK: - HMAC-SHA1计算
    private static func hmacSHA1(key: String, data: String) -> String {
        let keyData = key.data(using: .utf8)!
        let dataData = data.data(using: .utf8)!
        
        var result = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        keyData.withUnsafeBytes { keyBytes in
            dataData.withUnsafeBytes { dataBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyBytes.bindMemory(to: UInt8.self).baseAddress, keyData.count, dataBytes.bindMemory(to: UInt8.self).baseAddress, dataData.count, &result)
            }
        }
        
        return result.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - SHA1哈希计算
    private static func sha1(data: String) -> String {
        let dataData = data.data(using: .utf8)!
        var result = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        dataData.withUnsafeBytes { bytes in
            CC_SHA1(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(dataData.count), &result)
        }
        
        return result.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - 数据模型
struct TencentCOSCredentials: Codable {
    let tmpSecretId: String
    let tmpSecretKey: String
    let sessionToken: String
    let startTime: Int
    let expiredTime: Int
}

// MARK: - 错误类型
enum TencentCOSError: Error {
    case invalidURL
    case networkError(String)
    case credentialsError(String)
    case uploadFailed(String)
    case invalidResponse(String)
    case fileSizeExceeded(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .credentialsError(let message):
            return "认证错误: \(message)"
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        case .invalidResponse(let message):
            return "响应错误: \(message)"
        case .fileSizeExceeded(let message):
            return "文件大小错误: \(message)"
        }
    }
}