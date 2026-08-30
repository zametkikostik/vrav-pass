/* Optional shared object so Gradle packs native code.
 * Actual ML-KEM calls go through Dart FFI → liboqs.so directly.
 */
#include <android/log.h>

__attribute__((constructor))
static void vrav_oqs_loader_init(void) {
  __android_log_print(ANDROID_LOG_INFO, "vrav_pass", "native loader present");
}
