# ``ProvisionInfoKit``

ProvisionInfoKit is a Swift library for parsing provisioning profiles. It gives you all the metadata fields,
entitlements, device list and certificates in the profile.



## Usage

```swift
let data = try Data(contentsOf: url)
let profile = try Profile(data: data)
```
