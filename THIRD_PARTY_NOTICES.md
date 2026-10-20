# Third-party notices — iSelfie SDK

The iSelfie SDK is proprietary software of AiZtech Labs Inc. (see [LICENSE](LICENSE)). It
includes, or depends on, the third-party components below, each under its own license. Those
licenses govern those components.

## iOS (`ISelfieSDK.xcframework`)

Linked statically inside the framework, unmodified:

| Component | License |
|---|---|
| MediaPipe Tasks Vision and Tasks Common 0.10.9, © Google LLC | Apache License 2.0 |
| MediaPipe Face Landmarker model (`face_landmarker.task`: BlazeFace short range, Face Mesh V2, Blendshape V2), © Google LLC — identical to Google's published file | Apache License 2.0 |
| TensorFlow Lite, Abseil, FlatBuffers, ruy, gemmlowp (built into MediaPipe) | Apache License 2.0 |
| Protocol Buffers, XNNPACK, glog (built into MediaPipe) | BSD 3-Clause |
| OpenCV (built into MediaPipe) | BSD 3-Clause / Apache License 2.0, depending on version |
| cpuinfo, pthreadpool (built into MediaPipe) | BSD 2-Clause |
| FarmHash, stb_image (built into MediaPipe) | MIT |
| Eigen (built into MediaPipe) | Mozilla Public License 2.0 — unmodified; source at https://gitlab.com/libeigen/eigen |

The icons are Apple's SF Symbols, drawn by the system at run time and not included in the SDK.

## Android (`ai.iselfie:iselfie-sdk`)

Bundled inside the AAR:

| Component | License |
|---|---|
| MediaPipe Face Landmarker model (`face_landmarker.task`), © Google LLC — identical to Google's published file | Apache License 2.0 |
| Material Icons (some of the icons), © Google LLC | Apache License 2.0 |

Dependencies, downloaded by the app's build from Google's Maven repository and Maven Central:

| Component | License |
|---|---|
| AndroidX: CameraX, Activity, Lifecycle and their AndroidX dependencies | Apache License 2.0 |
| CameraX `camera-core` includes libyuv | BSD 3-Clause |
| MediaPipe Tasks Vision / Tasks Core | Apache License 2.0 |
| Kotlin standard library, kotlinx.coroutines, kotlinx.serialization | Apache License 2.0 |
| Guava, Flogger, AutoValue, Error Prone, J2ObjC and JSR-305 annotations, javax.inject, JSpecify, JetBrains annotations, Firebase encoders, Google datatransport | Apache License 2.0 |
| Protocol Buffers (`protobuf-javalite`) | BSD 3-Clause |
| Checker Framework `checker-compat-qual` | MIT (dual-licensed GPL 2.0 with Classpath Exception / MIT) |
| Animal Sniffer annotations | MIT |

## License texts

- Apache License 2.0: https://www.apache.org/licenses/LICENSE-2.0
- BSD 3-Clause: https://opensource.org/license/bsd-3-clause
- BSD 2-Clause: https://opensource.org/license/bsd-2-clause
- MIT: https://opensource.org/license/mit
- Mozilla Public License 2.0: https://www.mozilla.org/MPL/2.0/
