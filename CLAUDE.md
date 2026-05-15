# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is an early-stage Xcode 26 SwiftUI project. As of writing, the working tree contains only the default SwiftUI scaffold (`OpenType/OpenTypeApp.swift`, `OpenType/ContentView.swift`) plus four currently-empty placeholder directories at the repo root: `KeyboardExtension/`, `OpenTypeKeyboard/`, `Shared/`, `Documentation/`. The staged-but-deleted `UsageTracker.swift` under `KeyboardExtension 2/` and `Shared/KeyboardExtension/` in `git status` is leftover scaffolding, not active work — do not try to "restore" it without checking with the user.

There is no test target, no Swift Package manifest, no CI, and no linter config. The only build product is the `OpenType` iOS app.

## Build & run

The project is an Xcode project (not a Swift Package). Open `OpenType.xcodeproj` in Xcode and build the `OpenType` scheme, or from the command line:

```sh
# Build for simulator
xcodebuild -project OpenType.xcodeproj -scheme OpenType \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean
xcodebuild -project OpenType.xcodeproj -scheme OpenType clean
```

There is no `test` action configured — adding one requires a new test target.

## Architecture notes that aren't obvious from the code

- **Xcode file-system synchronized group.** The `OpenType` target uses a `PBXFileSystemSynchronizedRootGroup` (`project.pbxproj`). Any Swift / asset file dropped into the `OpenType/` directory is picked up automatically — **do not hand-edit `project.pbxproj` to register new files** in that group. Adding entirely new targets (e.g. a Keyboard Extension) still requires Xcode UI / pbxproj edits.

- **Swift 6 MainActor-by-default.** Build settings enable `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`. New types/functions are implicitly `@MainActor`-isolated unless explicitly marked `nonisolated` or moved to another actor. Keep this in mind when adding background work, networking, or shared state.

- **iOS 26.2 deployment target, universal (iPhone + iPad).** `IPHONEOS_DEPLOYMENT_TARGET = 26.2`, `TARGETED_DEVICE_FAMILY = "1,2"`. Don't add availability-gated fallbacks for older iOS — they aren't reachable.

- **Bundle identifier / signing.** `PRODUCT_BUNDLE_IDENTIFIER = HamzaBinMubeen.OpenType`, automatic signing, development team `F485M2N7DD`. If you add a new target (e.g. keyboard extension), it will need its own bundle id under the same prefix and likely an App Group entitlement to share data with the host app.

- **No Info.plist file on disk.** `GENERATE_INFOPLIST_FILE = YES` — Info.plist keys are set via `INFOPLIST_KEY_*` build settings in `project.pbxproj`, not a checked-in plist. Add new keys there.
