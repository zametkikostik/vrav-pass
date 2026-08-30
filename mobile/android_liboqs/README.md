# Shipping liboqs on Android

Flutter loads `liboqs.so` via `DynamicLibrary.open('liboqs.so')` (see `ml_kem_ffi.dart`).

## Option A — prebuilt `.so` into jniLibs

After `flutter create .`:

```text
mobile/android/app/src/main/jniLibs/
  arm64-v8a/liboqs.so
  armeabi-v7a/liboqs.so
  x86_64/liboqs.so
```

Build liboqs with the NDK for each ABI, or download community builds if you trust the source.

### NDK build sketch

```bash
export ANDROID_NDK=$ANDROID_HOME/ndk/<version>
cmake -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release -DOQS_USE_OPENSSL=OFF \
  -S liboqs -B build-arm64
cmake --build build-arm64 -j
# copy liboqs.so → jniLibs/arm64-v8a/
```

Repeat for `armeabi-v7a` and `x86_64`.

## Option B — CMake externalNativeBuild

See `CMakeLists.txt.example` in this folder. Copy into
`android/app/src/main/cpp/` and wire `externalNativeBuild` in `build.gradle`
**after** platform folders exist.

## Verify at runtime

```dart
import 'package:vrav_pass/core/crypto/pq/pq_factory.dart';
print(isPostQuantumNative); // true if .so loaded
```

Without `.so`, app still runs with the non-PQ stub.
