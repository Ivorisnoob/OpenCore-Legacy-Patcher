"""
modern_wireless.py: Modern Wireless detection
"""

from ..base import BaseHardware, HardwareVariant

from ...base import PatchType

from .....constants  import Constants
from .....detections import device_probe

from .....datasets.os_data import os_data
from .....datasets          import bluetooth_coex_data


class ModernWireless(BaseHardware):

    def __init__(self, xnu_major, xnu_minor, os_build, global_constants: Constants) -> None:
        super().__init__(xnu_major, xnu_minor, os_build, global_constants)


    def name(self) -> str:
        """
        Display name for end users
        """
        return f"{self.hardware_variant()}: Modern Wireless"


    def present(self) -> bool:
        """
        Targeting Modern Wireless
        """
        return isinstance(self._computer.wifi, device_probe.Broadcom) and (
            self._computer.wifi.chipset in [
                device_probe.Broadcom.Chipsets.AirPortBrcm4360,
                device_probe.Broadcom.Chipsets.AirportBrcmNIC,
                # We don't officially support this chipset, however we'll throw a bone to hackintosh users
                device_probe.Broadcom.Chipsets.AirPortBrcmNICThirdParty,
            ]
        )


    def native_os(self) -> bool:
        """
        Dropped support with macOS 14, Sonoma
        """
        return self._xnu_major < os_data.sonoma.value


    def hardware_variant(self) -> HardwareVariant:
        """
        Type of hardware variant
        """
        return HardwareVariant.NETWORKING


    def unpatch_required(self) -> str | None:
        return "2.4.0"


    def _patches_modern_wireless_common_extended(self) -> dict:
        """
        Extended modern wireless patches
        """
        if self._xnu_major > os_data.sonoma:
            return {}

        return {
            "Modern Wireless Extended": {
                PatchType.OVERWRITE_SYSTEM_VOLUME: {
                    "/usr/libexec": {
                        "airportd": f"13.7.2-{self._xnu_major}",
                    },
                },
                PatchType.MERGE_SYSTEM_VOLUME: {
                    "/System/Library/Frameworks": {
                        "CoreWLAN.framework": f"13.7.2-{self._xnu_major}",
                    },
                    "/System/Library/PrivateFrameworks": {
                        "CoreWiFi.framework":  f"13.7.2-{self._xnu_major}",
                    },
                },
            },
        }


    def _patches_modern_wireless_common(self) -> dict:
        """
        Common modern wireless patches
        """
        return {
            "Modern Wireless Common": {
                PatchType.OVERWRITE_SYSTEM_VOLUME: {
                    "/usr/libexec": {
                        "wifip2pd": f"13.7.2-{self._xnu_major}",
                    },
                },
                PatchType.MERGE_SYSTEM_VOLUME: {
                    "/System/Library/PrivateFrameworks": {
                        "IO80211.framework":        f"13.7.2-{self._xnu_major}",
                        "WiFiPeerToPeer.framework": f"13.7.2-{self._xnu_major}",
                    },
                },
            },
        }


    def _patches_modern_wireless_bluetooth_coexistence(self) -> dict:
        """
        Bluetooth coexistence patches, airportd no longer loads profiles for our cards
        """
        if self._xnu_major < os_data.sequoia:
            return {}

        if self._computer.real_board_id not in bluetooth_coex_data.bluetooth_coex_profiles:
            return {}

        return {
            "Modern Wireless Bluetooth Coexistence": {
                PatchType.OVERWRITE_SYSTEM_VOLUME: {
                    "/usr/libexec": {
                        "oclp-btcoex": str(self._constants.btcoex_helper_root_path),
                    },
                },
            },
        }


    def patches(self) -> dict:
        """
        Dictionary of patches
        """
        if self.native_os() is True:
            return {}

        return {
            **self._patches_modern_wireless_common(),
            **self._patches_modern_wireless_common_extended(),
            **self._patches_modern_wireless_bluetooth_coexistence(),
        }

        return _base
