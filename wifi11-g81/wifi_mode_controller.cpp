/*
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <android-base/logging.h>
#include <android-base/macros.h>
#include <private/android_filesystem_config.h>

#include <chrono>
#include <thread>
#include <unistd.h>

#include "wifi_mode_controller.h"

using android::hardware::wifi::V1_0::IfaceType;
using android::wifi_hal::DriverTool;

namespace {
// The MT6580 legacy driver publishes wlan0 asynchronously after DriverTool
// finishes loading wlan_drv.ko and the init property edge writes /dev/wmtWifi.
// The Android framework asks the HAL to create the STA interface immediately;
// allowing the callback to return before wlan0 exists races wpa_supplicant and
// produces "Could not read interface wlan0 flags: No such device".  Wait at
// this HAL boundary so the framework only starts supplicant after the netdev
// is visible.  The timeout keeps a genuinely failed driver load bounded.
bool waitForStaNetdev() {
  constexpr int kPollMs = 50;
  constexpr int kTimeoutMs = 5000;
  for (int elapsed = 0; elapsed < kTimeoutMs; elapsed += kPollMs) {
    if (access("/sys/class/net/wlan0", F_OK) == 0) {
      LOG(INFO) << "MTK WLAN netdev wlan0 ready after " << elapsed << " ms";
      return true;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(kPollMs));
  }
  LOG(ERROR) << "MTK WLAN netdev wlan0 did not appear within " << kTimeoutMs
             << " ms after driver load";
  return false;
}

int convertIfaceTypeToFirmwareMode(IfaceType type) {
  int mode;
  switch (type) {
    case IfaceType::AP:
      mode = DriverTool::kFirmwareModeAp;
      break;
    case IfaceType::P2P:
      mode = DriverTool::kFirmwareModeP2p;
      break;
    case IfaceType::NAN:
      // NAN is exposed in STA mode currently.
      mode = DriverTool::kFirmwareModeSta;
      break;
    case IfaceType::STA:
      mode = DriverTool::kFirmwareModeSta;
      break;
  }
  return mode;
}
}

namespace android {
namespace hardware {
namespace wifi {
namespace V1_1 {
namespace implementation {
namespace mode_controller {

WifiModeController::WifiModeController() : driver_tool_(new DriverTool) {}

bool WifiModeController::isFirmwareModeChangeNeeded(IfaceType type) {
  return driver_tool_->IsFirmwareModeChangeNeeded(
      convertIfaceTypeToFirmwareMode(type));
}

bool WifiModeController::changeFirmwareMode(IfaceType type) {
  if (!driver_tool_->LoadDriver()) {
    LOG(ERROR) << "Failed to load WiFi driver";
    return false;
  }
  if (type == IfaceType::STA && !waitForStaNetdev()) {
    LOG(ERROR) << "Refusing STA start before wlan0 is present";
    return false;
  }
  // MT6580 exposes STA and the AP-capable p2p0 netdev concurrently from one
  // firmware path.  Writing the legacy firmware-path sysfs node here makes
  // the chip reconfiguration fail (ERROR_NOT_SUPPORTED/4) after STA teardown.
  // The driver is already in its only usable mode once loaded; keep that mode
  // and let hostapd switch p2p0 to AP in place.
  if (type == IfaceType::STA) {
    return true;
  }
  if (!driver_tool_->ChangeFirmwareMode(convertIfaceTypeToFirmwareMode(type))) {
    LOG(ERROR) << "Failed to change firmware mode";
    return false;
  }
  return true;
}

bool WifiModeController::deinitialize() {
  if (!driver_tool_->UnloadDriver()) {
    LOG(ERROR) << "Failed to unload WiFi driver";
    return false;
  }
  return true;
}
}  // namespace mode_controller
}  // namespace implementation
}  // namespace V1_1
}  // namespace wifi
}  // namespace hardware
}  // namespace android
