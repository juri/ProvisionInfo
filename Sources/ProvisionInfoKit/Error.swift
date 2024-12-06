import Foundation

/// `ProvisionInfoError` is the error thrown when profile parsing fails.
public enum ProvisionInfoError: Error {
    case certificateReadFailure
    case certificateCopyDataFailure(Error?)
    case cmsDecoderCreationFailure(OSStatus)
    case cmsDecoderCopyFailure(OSStatus)
    case cmsDecoderFinalizeFailure(OSStatus)
    case cmsDecoderUpdateFailure(OSStatus)
    case entitlementsDecodingFailure
    case profileDeserializationFailure
    case summaryReadFailure
}
