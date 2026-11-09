"""
bluetooth_coex_data.py: Wi-Fi/Bluetooth coexistence profiles for Modern Wireless
"""

"""
Profiles used by airportd 13.7.2, keyed by board ID, loaded by oclp-btcoex on macOS 15+
- Profile Mode:  BTC_PROF_MODE
- Chains:        BTC_PROF_NUM_CHAINS
- ACK:           BTC_PROF_CHAIN_ACK_ARRAY
- Power Offsets: BTC_PROF_CHAIN_POWER_OFFSET_ARRAY
- Desense:       BTC_PROF_DESENSE, BTC_PROF_DESENSE_LEVEL, BTC_PROF_DESENSE_THRESH_HIGH, BTC_PROF_DESENSE_THRESH_LOW
"""


bluetooth_coex_profiles = {
    "Mac-66F35F19FE2A0D05": {  # MacBookAir5,1
        "Profile Mode":  0,
        "Chains":        3,
        "ACK":           [1, 1, 1],
        "Power Offsets": [0, -7, -7],
        "Desense":       [1, 1, 0, 0],
    },
    "Mac-2E6FAB96566FE58C": {  # MacBookAir5,2
        "Profile Mode":  0,
        "Chains":        3,
        "ACK":           [1, 1, 1],
        "Power Offsets": [0, -7, -7],
        "Desense":       [1, 1, 0, 0],
    },
    "Mac-35C1E88140C3E6CF": {  # MacBookAir6,1
        "Profile Mode":  7,
        "Chains":        2,
        "ACK":           [1, 0],
        "Power Offsets": [-2, 0],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-7DF21CB3ED6977E5": {  # MacBookAir6,2
        "Profile Mode":  7,
        "Chains":        2,
        "ACK":           [1, 0],
        "Power Offsets": [0, 0],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-9F18E312C5C2BF0B": {  # MacBookAir7,1
        "Profile Mode":  7,
        "Chains":        2,
        "ACK":           [1, 0],
        "Power Offsets": [-2, 0],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-937CB26E2E02BB01": {  # MacBookAir7,2
        "Profile Mode":  7,
        "Chains":        2,
        "ACK":           [1, 0],
        "Power Offsets": [0, 0],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-4B7AC7E43945597E": {  # MacBookPro9,1
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [1, 1, 1],
        "Power Offsets": [0, 0, 0],
        "Desense":       [0, 0, 0, 0],
    },
    "Mac-6F01561E16C75D06": {  # MacBookPro9,2
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [1, 1, 1],
        "Power Offsets": [0, 0, 0],
        "Desense":       [0, 0, 0, 0],
    },
    "Mac-C3EC7CD22292981F": {  # MacBookPro10,1
        "Profile Mode":  0,
        "Chains":        3,
        "ACK":           [1, 1, 1],
        "Power Offsets": [0, -7, -7],
        "Desense":       [1, 1, 0, 0],
    },
    "Mac-AFD8A9D944EA4843": {  # MacBookPro10,2
        "Profile Mode":  0,
        "Chains":        3,
        "ACK":           [1, 1, 1],
        "Power Offsets": [0, -7, -7],
        "Desense":       [1, 1, 0, 0],
    },
    "Mac-189A3D4F975D5FFC": {  # MacBookPro11,1
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 0, 1],
        "Power Offsets": [0, 0, -7],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-3CBD00234E554E41": {  # MacBookPro11,2
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 0, 1],
        "Power Offsets": [0, 0, -5],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-2BD1B31983FE1663": {  # MacBookPro11,3
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 0, 1],
        "Power Offsets": [0, 0, -5],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-06F11FD93F0323C5": {  # MacBookPro11,4
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 0, 1],
        "Power Offsets": [0, 0, -5],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-06F11F11946D27C5": {  # MacBookPro11,5
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 0, 1],
        "Power Offsets": [0, 0, -5],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-E43C1C25D4880AD6": {  # MacBookPro12,1
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 0, 1],
        "Power Offsets": [0, 0, -7],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-F60DEB81FF30ACF6": {  # MacPro6,1
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [0, 1, 0],
        "Power Offsets": [0, 0, 0],
        "Desense":       [1, 3, -55, -60],
    },
    "Mac-031AEE4D24BFF0B1": {  # Macmini6,1
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [1, 0, 1],
        "Power Offsets": [0, 0, 0],
        "Desense":       [0, 0, 0, 0],
    },
    "Mac-F65AE981FFA204ED": {  # Macmini6,2
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [1, 0, 1],
        "Power Offsets": [0, 0, 0],
        "Desense":       [0, 0, 0, 0],
    },
    "Mac-35C5E08120C7EEAF": {  # Macmini7,1
        "Profile Mode":  7,
        "Chains":        3,
        "ACK":           [1, 0, 1],
        "Power Offsets": [0, 0, 0],
        "Desense":       [0, 0, 0, 0],
    },
}
