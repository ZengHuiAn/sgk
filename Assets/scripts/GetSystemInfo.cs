using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class GetSystemInfo {
        public static bool batteryStatus() {
            return SystemInfo.batteryStatus == BatteryStatus.Charging;
        }

        public static float batteryLevel() {
#if UNITY_EDITOR
            return 1;
#else
            return SystemInfo.batteryLevel;
#endif
        }

        public static int networkStatus() {
            if (Application.internetReachability == NetworkReachability.ReachableViaCarrierDataNetwork) {   //4G
                return 1;
            }
            else if (Application.internetReachability == NetworkReachability.ReachableViaLocalAreaNetwork) { //wifi
                return 2;
            } 
            else {
                return 1;
            }
        }
    }
}