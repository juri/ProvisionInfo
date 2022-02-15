import Foundation

public func hexifyData(_ data: Data) -> String {
    data
        .map {
            let hex = String($0, radix: 16, uppercase: true)
            return $0 < 0x10 ? "0\(hex)" : hex
        }
        .joined(separator: " ")
}

