import Foundation

public enum ProvisionInfoError: Error {
    case certificateReadFailure
    case certificateCopyDataFailure(Error?)
    case cmsDecoderCreationFailure(OSStatus)
    case cmsDecoderCopyFailure(OSStatus)
    case cmsDecoderFinalizeFailure(OSStatus)
    case cmsDecoderUpdateFailure(OSStatus)
    case profileDeserializationFailure
    case summaryReadFailure
}
