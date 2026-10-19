#include <android/hidl/base/1.0/types.h>
#include <string>

namespace android { namespace hidl { namespace base { namespace V1_0 {
std::string toString(const DebugInfo& info) {
    return std::string("pid=") + std::to_string(info.pid) + ",ptr=" +
           std::to_string(info.ptr) + ",arch=" + std::to_string(info.arch);
}
}}}}
