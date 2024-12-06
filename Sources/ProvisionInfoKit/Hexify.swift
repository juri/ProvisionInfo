import Foundation

/// `hexifyData` converts a `Data` value to a all-caps hex string with
/// each byte separated by spaces, e.g. `01 05 A0 FF`.
package func hexifyData(_ data: Data) -> String {
    data
        .map {
            let hex = String($0, radix: 16, uppercase: true)
            return $0 < 0x10 ? "0\(hex)" : hex
        }
        .joined(separator: " ")
}
