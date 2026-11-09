/*
    ------------------------------------------------
    OpenCore Legacy Patcher Bluetooth Coexistence Helper
    ------------------------------------------------
    Since macOS 15, airportd no longer loads Wi-Fi/Bluetooth
    coexistence profiles for Modern Wireless cards, causing
    Bluetooth audio stutter while Wi-Fi is on 2.4 GHz.
    ------------------------------------------------
    This tool loads the profiles airportd 13.7.2 used,
    and stays running as a LaunchDaemon as the driver drops
    them on reset, sleep and while joining a network.
    ------------------------------------------------
*/

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <net/if.h>
#include <os/log.h>
#include <sys/ioctl.h>
#include <sys/socket.h>

#define UTILITY_VERSION "1.1.0"

#define IO80211_PATH "/System/Library/PrivateFrameworks/IO80211.framework/IO80211"

#define SIOCSA80211 2150132168UL
#define SIOCGA80211 3223873993UL

#define APPLE80211_IOC_CHANNEL         4
#define APPLE80211_IOC_BTCOEX_MODE     87
#define APPLE80211_IOC_BTCOEX_PROFILES 221

#define BAND_2GHZ          8
#define BAND_5GHZ          2
#define NUM_2GHZ_PROFILES  3
#define MAX_CHAINS         3
#define DAEMON_INTERVAL    10

#define OCLP_BTC_ERROR_INVALID_ARGUMENTS 64
#define OCLP_BTC_ERROR_FAILED            1

struct apple80211req {
    char      req_if_name[IFNAMSIZ];
    int       req_type;
    int       req_val;
    u_int32_t req_len;
    void     *req_data;
};

typedef struct __Apple80211 *Apple80211Ref;
static int (*Apple80211Open)(Apple80211Ref *ref);
static int (*Apple80211BindToInterface)(Apple80211Ref ref, CFStringRef ifname);
static int (*Apple80211Close)(Apple80211Ref ref);
static int (*Apple80211Set)(Apple80211Ref ref, int type, int index, void *data, int len);

typedef struct {
    int profileMode;
    int coexMode;
    int chains;
    int ack[MAX_CHAINS];
    int power[MAX_CHAINS];
    int desense[4];
} CoexConfig;

static os_log_t logger;
static BOOL interactive;


// Print when run from a terminal, otherwise log to the unified log
static void logMessage(const char *format, ...) __printflike(1, 2);
static void logMessage(const char *format, ...) {
    char message[512];
    va_list args;
    va_start(args, format);
    vsnprintf(message, sizeof(message), format, args);
    va_end(args);
    if (interactive) {
        printf("%s\n", message);
    } else {
        os_log(logger, "%{public}s", message);
    }
}

int apple80211Ioctl(int s, unsigned long cmd, const char *ifname, int type, void *data, unsigned len, int val, int *outVal) {
    struct apple80211req req;
    memset(&req, 0, sizeof(req));
    strlcpy(req.req_if_name, ifname, sizeof(req.req_if_name));
    req.req_type = type;
    req.req_val  = val;
    req.req_len  = len;
    req.req_data = data;
    int result = ioctl(s, cmd, &req);
    if (outVal) {
        *outVal = req.req_val;
    }
    return result < 0 ? errno : 0;
}

int findWiFiInterface(int s, char *out, size_t outLen) {
    for (int i = 0; i < 8; i++) {
        char ifname[IFNAMSIZ];
        snprintf(ifname, sizeof(ifname), "en%d", i);
        unsigned buffer[16] = {1};
        if (apple80211Ioctl(s, SIOCGA80211, ifname, APPLE80211_IOC_CHANNEL, buffer, sizeof(buffer), 0, NULL) == 0) {
            strlcpy(out, ifname, outLen);
            return 0;
        }
    }
    return -1;
}

int getCoexMode(int s, const char *ifname) {
    unsigned request[2] = {1, 0};
    int value = -1;
    if (apple80211Ioctl(s, SIOCGA80211, ifname, APPLE80211_IOC_BTCOEX_MODE, request, sizeof(request), 0, &value)) {
        return -1;
    }
    return value;
}

int setCoexMode(int s, const char *ifname, int mode) {
    unsigned request[2] = {1, (unsigned)mode};
    return apple80211Ioctl(s, SIOCSA80211, ifname, APPLE80211_IOC_BTCOEX_MODE, request, sizeof(request), mode, NULL);
}

// Returns the number of 2.4 GHz profiles loaded and the first profile's mode
int getProfiles(int s, const char *ifname, int *firstMode) {
    unsigned buffer[160];
    memset(buffer, 0, sizeof(buffer));
    if (apple80211Ioctl(s, SIOCGA80211, ifname, APPLE80211_IOC_BTCOEX_PROFILES, buffer, 8 + 141 * 4, 0, NULL)) {
        return -1;
    }
    if (firstMode) {
        *firstMode = (int)buffer[3];
    }
    return (int)buffer[2];
}

NSArray *intArray(const int *values, int count) {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [array addObject:@(values[i])];
    }
    return array;
}

NSDictionary *buildProfile(int mode, const int *desense, int chains, const int *ack, const int *power) {
    BOOL anyChainWithoutAck = NO;
    for (int i = 0; i < chains; i++) {
        if (ack[i] == 0) {
            anyChainWithoutAck = YES;
        }
    }
    return @{
        @"BTC_PROF_MODE":                      @(mode),
        @"BTC_PROF_DESENSE":                   @(desense[0]),
        @"BTC_PROF_DESENSE_LEVEL":             @(desense[1]),
        @"BTC_PROF_DESENSE_THRESH_HIGH":       @(desense[2]),
        @"BTC_PROF_DESENSE_THRESH_LOW":        @(desense[3]),
        @"BTC_PROF_NUM_CHAINS":                @(chains),
        @"BTC_PROF_CHAIN_ACK_ARRAY":           intArray(ack, chains),
        @"BTC_PROF_CHAIN_POWER_OFFSET_ARRAY":  intArray(power, chains),
        @"BTC_PROF_WLRSSI_THRESH":             @(-70),
        @"BTC_PROF_WLRSSI_HYST":               @0,
        @"BTC_PROF_BTRSSI_THRESH":             @(-70),
        @"BTC_PROF_BTRSSI_HYST":               @0,
        @"BTC_PROF_NUM_DESENSE_LEVELS":        @2,
        @"BTC_PROF_SISO_RESP_EN_ARRAY":        @[@(anyChainWithoutAck), @(anyChainWithoutAck)],
        @"BTC_PROF_MAX_SISO_RESP_POWER_ARRAY": @[@127, @127],
    };
}

// 2.4 GHz: OFF, LIGHT and HEAVY profiles. 5 GHz: a single profile with coexistence off.
int loadProfiles(const char *ifname, const CoexConfig *config, int *result2G, int *result5G) {
    static const int noDesense[4] = {0, 0, 0, 0};
    int zeros[MAX_CHAINS] = {0};
    int ackAll[MAX_CHAINS];
    int ackOff[MAX_CHAINS];
    for (int i = 0; i < MAX_CHAINS; i++) {
        ackAll[i] = 1;
        ackOff[i] = 0x01010101; // airportd fills the OFF profile's array with memset(1)
    }

    NSDictionary *profiles2G = @{
        @"BTC_PROF_BAND":     @(BAND_2GHZ),
        @"BTC_PROF_NUM":      @(NUM_2GHZ_PROFILES),
        @"BTC_PROF_PROFILES": @[
            buildProfile(config->profileMode, noDesense,       config->chains, ackOff,      zeros),
            buildProfile(config->profileMode, noDesense,       config->chains, config->ack, config->power),
            buildProfile(config->profileMode, config->desense, config->chains, config->ack, config->power),
        ],
    };
    NSDictionary *profiles5G = @{
        @"BTC_PROF_BAND":     @(BAND_5GHZ),
        @"BTC_PROF_NUM":      @1,
        @"BTC_PROF_PROFILES": @[ buildProfile(0, noDesense, config->chains, ackAll, zeros) ],
    };

    Apple80211Ref ref = NULL;
    CFStringRef name = CFStringCreateWithCString(NULL, ifname, kCFStringEncodingUTF8);
    int result = Apple80211Open(&ref);
    if (result == 0) {
        result = Apple80211BindToInterface(ref, name);
    }
    CFRelease(name);
    if (result != 0) {
        if (ref) {
            Apple80211Close(ref);
        }
        return result;
    }
    *result2G = Apple80211Set(ref, APPLE80211_IOC_BTCOEX_PROFILES, 0, (__bridge void *)profiles2G, 8);
    *result5G = Apple80211Set(ref, APPLE80211_IOC_BTCOEX_PROFILES, 0, (__bridge void *)profiles5G, 8);
    Apple80211Close(ref);
    return 0;
}

BOOL loadIO80211(void) {
    void *handle = dlopen(IO80211_PATH, RTLD_LAZY);
    if (!handle) {
        return NO;
    }
    Apple80211Open            = dlsym(handle, "Apple80211Open");
    Apple80211BindToInterface = dlsym(handle, "Apple80211BindToInterface");
    Apple80211Close           = dlsym(handle, "Apple80211Close");
    Apple80211Set             = dlsym(handle, "Apple80211Set");
    return Apple80211Open && Apple80211BindToInterface && Apple80211Close && Apple80211Set;
}

// Parses a comma separated list of integers, returns the count or -1
int parseList(const char *argument, int *out, int max) {
    int count = 0;
    char *copy = strdup(argument);
    char *cursor = copy;
    char *token;
    while ((token = strsep(&cursor, ",")) != NULL) {
        char *end;
        long value = strtol(token, &end, 0);
        if (count == max || *token == '\0' || *end != '\0') {
            count = -1;
            break;
        }
        out[count++] = (int)value;
    }
    free(copy);
    return count;
}

void printUsage(void) {
    fprintf(stderr,
        "Usage: oclp-btcoex [--status | --ensure | --apply | --daemon] --profile-mode M --chains N\n"
        "                   --ack a,b,c --power a,b,c --desense enable,level,high,low [--coex-mode M]\n");
}


// Checks the driver's state, and loads the profiles and coexistence mode when needed
int checkCoexistence(const CoexConfig *config, BOOL ensure, BOOL apply) {
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) {
        logMessage("Failed to create socket: %s", strerror(errno));
        return OCLP_BTC_ERROR_FAILED;
    }

    // No interface while Wi-Fi is off, the LaunchDaemon will try again
    char ifname[IFNAMSIZ];
    if (findWiFiInterface(s, ifname, sizeof(ifname)) != 0) {
        if (!ensure && !apply) {
            logMessage("No Wi-Fi interface found");
        }
        close(s);
        return 0;
    }

    int firstMode = -1;
    int profileCount = getProfiles(s, ifname, &firstMode);
    int coexMode = getCoexMode(s, ifname);
    BOOL profilesLoaded = profileCount == NUM_2GHZ_PROFILES && firstMode == config->profileMode;
    BOOL modeSet = coexMode == config->coexMode;

    if (!ensure && !apply) {
        logMessage("%s: profiles %d (%s), coex mode %d (%s)", ifname,
                   profileCount, profilesLoaded ? "loaded" : "missing",
                   coexMode, modeSet ? "set" : "not set");
        close(s);
        return (profilesLoaded && modeSet) ? 0 : OCLP_BTC_ERROR_FAILED;
    }

    if (ensure && profilesLoaded && modeSet) {
        close(s);
        return 0;
    }

    int openResult = 0;
    int result2G = 0;
    int result5G = 0;
    int modeResult = 0;
    if (apply || !profilesLoaded) {
        openResult = loadProfiles(ifname, config, &result2G, &result5G);
    }
    if (apply || !profilesLoaded || !modeSet) {
        modeResult = setCoexMode(s, ifname, config->coexMode);
    }

    // The driver may apply the mode a moment later, ex. while joining a network
    int newProfileCount = -1;
    int newCoexMode = -1;
    BOOL success = NO;
    for (int attempt = 0; attempt < 10 && !success; attempt++) {
        if (attempt > 0) {
            usleep(200000);
        }
        newProfileCount = getProfiles(s, ifname, &firstMode);
        newCoexMode = getCoexMode(s, ifname);
        success = newProfileCount == NUM_2GHZ_PROFILES && firstMode == config->profileMode && newCoexMode == config->coexMode;
    }

    logMessage("%s: %s coexistence (profiles %d -> %d, coex mode %d -> %d, errors %d/%d/%d/%d)", ifname,
               success ? "Restored" : "Failed to restore",
               profileCount, newProfileCount, coexMode, newCoexMode,
               openResult, result2G, result5G, modeResult);

    close(s);
    return success ? 0 : OCLP_BTC_ERROR_FAILED;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc == 2 && (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0)) {
            printf("%s\n", UTILITY_VERSION);
            return 0;
        }

        logger = os_log_create("com.dortania.opencore-legacy-patcher", "btcoex");

        BOOL ensure = NO;
        BOOL apply = NO;
        BOOL daemon = NO;
        CoexConfig config = { .profileMode = -1, .coexMode = 7, .chains = 0 };
        int ackCount = -1;
        int powerCount = -1;
        int desenseCount = -1;

        for (int i = 1; i < argc; i++) {
            const char *argument = argv[i];
            const char *value = (i + 1 < argc) ? argv[i + 1] : NULL;
            if (strcmp(argument, "--status") == 0) {
                ensure = NO;
                apply = NO;
            } else if (strcmp(argument, "--ensure") == 0) {
                ensure = YES;
                apply = NO;
            } else if (strcmp(argument, "--apply") == 0) {
                ensure = NO;
                apply = YES;
            } else if (strcmp(argument, "--daemon") == 0) {
                daemon = YES;
            } else if (value && strcmp(argument, "--profile-mode") == 0) {
                config.profileMode = atoi(value);
                i++;
            } else if (value && strcmp(argument, "--coex-mode") == 0) {
                config.coexMode = atoi(value);
                i++;
            } else if (value && strcmp(argument, "--chains") == 0) {
                config.chains = atoi(value);
                i++;
            } else if (value && strcmp(argument, "--ack") == 0) {
                ackCount = parseList(value, config.ack, MAX_CHAINS);
                i++;
            } else if (value && strcmp(argument, "--power") == 0) {
                powerCount = parseList(value, config.power, MAX_CHAINS);
                i++;
            } else if (value && strcmp(argument, "--desense") == 0) {
                desenseCount = parseList(value, config.desense, 4);
                i++;
            } else {
                printUsage();
                return OCLP_BTC_ERROR_INVALID_ARGUMENTS;
            }
        }

        if (config.profileMode < 0 || config.chains < 1 || config.chains > MAX_CHAINS ||
            ackCount != config.chains || powerCount != config.chains || desenseCount != 4) {
            printUsage();
            return OCLP_BTC_ERROR_INVALID_ARGUMENTS;
        }

        interactive = isatty(STDOUT_FILENO);

        if (!loadIO80211()) {
            logMessage("Failed to load IO80211.framework");
            return OCLP_BTC_ERROR_FAILED;
        }

        // Stay resident, as the driver also drops the mode while rejoining a network
        while (daemon) {
            @autoreleasepool {
                checkCoexistence(&config, YES, NO);
            }
            sleep(DAEMON_INTERVAL);
        }

        return checkCoexistence(&config, ensure, apply);
    }
}
