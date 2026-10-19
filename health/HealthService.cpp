/* SPDX-License-Identifier: Apache-2.0 */
#include <health2/service.h>
#include <healthd/healthd.h>

void healthd_board_init(struct healthd_config* config) {
    // Kernel batt_vol is microvolts; BatteryMonitor converts it to millivolts.
    config->batteryVoltagePath = "/sys/class/power_supply/battery/batt_vol";
    // Kernel batt_temp is already in tenths of a degree Celsius.
    config->batteryTemperaturePath = "/sys/class/power_supply/battery/batt_temp";
}

int healthd_board_battery_update(struct android::BatteryProperties*) {
    return 0;
}

int main() {
    return health_service_main();
}
