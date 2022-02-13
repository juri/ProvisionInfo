import Foundation
import ProvisionInfoKit

@main
public enum ProvisionInfo {
    public static func main() throws {
        let path = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: false)
        let data = try Data(contentsOf: path)
        let rawProfile = try rawProfileInfo(data: data)
        let profile = profile(raw: rawProfile)
        let certInfos = try profile.developerCertificates.map(certInfo(data:))
        print("---- profile")
        dump(profile)
        print("---- cert infos")
        for cert in certInfos {
            dump(cert)
            if let fingerprint = cert.fingerprintSHA1 {
                print("Fingerprint SHA-1 hex:", hexifyData(fingerprint))
            }
            if let fingerprint = cert.fingerprintSHA256 {
                print("Fingerprint SHA-256 hex:", hexifyData(fingerprint))
            }
        }
        dump(certInfos)
        print("---- done")
    }
}
