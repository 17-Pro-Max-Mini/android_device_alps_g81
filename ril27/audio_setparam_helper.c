#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void (*string8_ctor_fn)(void *, const char *);
typedef void (*string8_dtor_fn)(void *);
typedef int (*audio_set_parameters_fn)(const void *);
typedef int (*audio_set_voice_volume_fn)(float);
typedef int (*audio_set_stream_volume_index_fn)(int, unsigned int, unsigned int);

int main(int argc, char **argv) {
    if (argc > 3 && !strcmp(argv[1], "stream")) {
        void *audio = dlopen("/system/lib/libaudioclient.so", RTLD_NOW | RTLD_GLOBAL);
        if (!audio) {
            fprintf(stderr, "audio dlopen failed: %s\n", dlerror());
            return 10;
        }
        audio_set_stream_volume_index_fn seti = (audio_set_stream_volume_index_fn)dlsym(
            audio, "_ZN7android11AudioSystem20setStreamVolumeIndexE19audio_stream_type_tij");
        if (!seti) {
            fprintf(stderr, "AudioSystem::setStreamVolumeIndex missing\n");
            return 12;
        }
        int stream = atoi(argv[2]);
        unsigned int index = (unsigned int)atoi(argv[3]);
        unsigned int device = argc > 4 ? (unsigned int)strtoul(argv[4], 0, 0) : 1;
        int result = seti(stream, index, device);
        printf("setStreamVolumeIndex(%d,%u,0x%x)=%d\n", stream, index, device, result);
        return result == 0 ? 0 : 13;
    }
    if (argc > 2 && (!strcmp(argv[1], "voice") || !strcmp(argv[1], "voice-volume"))) {
        void *audio = dlopen("/system/lib/libaudioclient.so", RTLD_NOW | RTLD_GLOBAL);
        if (!audio) {
            fprintf(stderr, "audio dlopen failed: %s\n", dlerror());
            return 10;
        }
        audio_set_voice_volume_fn setv = (audio_set_voice_volume_fn)dlsym(
            audio, "_ZN7android11AudioSystem14setVoiceVolumeEf");
        if (!setv) {
            fprintf(stderr, "AudioSystem::setVoiceVolume missing\n");
            return 12;
        }
        float value = (float)atof(argv[2]);
        int result = setv(value);
        printf("setVoiceVolume(%0.3f)=%d\n", value, result);
        return result == 0 ? 0 : 13;
    }
    const char *value = argc > 1 ? argv[1] : "Phone1Modem=MD1";
    void *audio = dlopen("/system/lib/libaudioclient.so", RTLD_NOW | RTLD_GLOBAL);
    if (!audio) {
        fprintf(stderr, "audio dlopen failed: %s\n", dlerror());
        return 10;
    }
    void *utils = dlopen("/system/lib/libutils.so", RTLD_NOW | RTLD_GLOBAL);
    if (!utils) {
        fprintf(stderr, "utils dlopen failed: %s\n", dlerror());
        return 11;
    }
    string8_ctor_fn ctor = (string8_ctor_fn)dlsym(utils, "_ZN7android7String8C1EPKc");
    string8_dtor_fn dtor = (string8_dtor_fn)dlsym(utils, "_ZN7android7String8D1Ev");
    audio_set_parameters_fn setp = (audio_set_parameters_fn)dlsym(
        audio, "_ZN7android11AudioSystem13setParametersERKNS_7String8E");
    if (!ctor || !dtor || !setp) {
        fprintf(stderr, "audio symbols missing\n");
        return 12;
    }
    unsigned char string8[64] = {0};
    ctor(string8, value);
    int result = setp(string8);
    dtor(string8);
    printf("setParameters(%s)=%d\n", value, result);
    return result == 0 ? 0 : 13;
}
