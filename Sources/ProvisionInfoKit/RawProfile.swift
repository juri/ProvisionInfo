import Foundation
import Security

/// `RawProfile` represents the fields of a profile as a dictionary. It's the result
/// of decoding the CMS data and then parsing the property list.
public struct RawProfile {
    public var fields: [String: Any]
}

extension RawProfile {
    /// Initializes a `RawProfile` with data of a provisioning profile file.
    public init(data: Data) throws(ProvisionInfoError) {
        let decoded = try decodeProfile(data: data)
        self.init(fields: decoded)
    }
}

func decodeProfile(data: Data) throws(ProvisionInfoError) -> [String: Any] {
    var decoder: CMSDecoder?
    var status: OSStatus = errSecSuccess

    status = CMSDecoderCreate(&decoder)
    guard status == errSecSuccess, let decoder else {
        throw ProvisionInfoError.cmsDecoderCreationFailure(status)
    }

    status = data.withUnsafeBytes { ptr in
        CMSDecoderUpdateMessage(decoder, ptr.baseAddress!, data.count)
    }
    guard status == errSecSuccess else {
        throw ProvisionInfoError.cmsDecoderUpdateFailure(status)
    }

    status = CMSDecoderFinalizeMessage(decoder)
    guard status == errSecSuccess else {
        throw ProvisionInfoError.cmsDecoderFinalizeFailure(status)
    }

    var decodedCFData: CFData?
    status = CMSDecoderCopyContent(decoder, &decodedCFData)
    guard status == errSecSuccess, let decodedCFData else {
        throw ProvisionInfoError.cmsDecoderCopyFailure(status)
    }

    let decodedData = decodedCFData as Data
    guard let dict = try? PropertyListSerialization.propertyList(
        from: decodedData, options: [], format: nil
    ) as? [String: Any] else {
        throw ProvisionInfoError.profileDeserializationFailure
    }

    return dict
}
