/*
 * Android 8.1's mtk-rilproxy references only
 * MTKPrimaryDevicesHalClient::getInstance().  The original client pulls the
 * audio/media/GUI stack into the Android 10 radio process, where it requires
 * private Bionic linker symbols.  This ABI bridge preserves the two virtual
 * methods used by the RIL audio-mode handler without loading that stack.
 */

#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

typedef struct {
    void **vptr;
} MtkPrimaryDevicesHalClient;

extern void string8_ctor(void *value) __asm__("_ZN7android7String8C1Ev");

static int set_parameters(void *self, const void *parameters) {
    pid_t child;
    int status = 0;
    char *const args[] = {"audio-setparam", "Phone1Modem=MD1", (char *)0};

    (void)self;
    (void)parameters;
    {
        int fd = open("/data/local/tmp/ril-audio-bridge.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd >= 0) { write(fd, "set\n", 4); close(fd); }
    }
    child = fork();
    if (child == 0) {
        execv("/vendor/bin/audio-setparam", args);
        _exit(127);
    }
    if (child < 0 || waitpid(child, &status, 0) < 0)
        return -1;
    return WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : -1;
}

static void activate_audio_path(void) {
    pid_t child = fork();
    int status = 0;
    char *const args[] = {"audio-setparam", "Phone1Modem=MD1", (char *)0};
    {
        int fd = open("/data/local/tmp/ril-audio-bridge.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd >= 0) { write(fd, "get\n", 4); close(fd); }
    }
    if (child == 0) {
        execv("/vendor/bin/audio-setparam", args);
        _exit(127);
    }
    if (child > 0)
        waitpid(child, &status, 0);
}

/* The ARM C++ ABI passes String8's return storage as the first argument. */
static void get_parameters(void *result, void *self, const void *keys) {
    (void)self;
    (void)keys;
    activate_audio_path();
    string8_ctor(result);
}

static void destroy(void *self) {
    (void)self;
}

static void *client_vtable[] = {
    (void *)0,
    (void *)0,
    (void *)set_parameters,
    (void *)get_parameters,
    (void *)destroy,
    (void *)destroy,
};

/* C++ ABI object pointers address the vtable after offset-to-top/typeinfo. */
static MtkPrimaryDevicesHalClient client = {&client_vtable[2]};

__attribute__((visibility("default")))
MtkPrimaryDevicesHalClient *get_instance(void)
    __asm__("_ZN7android26MTKPrimaryDevicesHalClient11getInstanceEv");

MtkPrimaryDevicesHalClient *get_instance(void) {
    int fd = open("/data/local/tmp/ril-audio-bridge.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) { write(fd, "inst\n", 5); close(fd); }
    return &client;
}
