/* MT6580 libmnl teardown compatibility for Android 10 ARM32 bionic.
 * Only libmnl's destroy import binds here. Valid destroys retain libc semantics.
 * Android 10 bionic uses the first atomic uint16_t and 0xffff destroyed marker.
 */
#if !defined(__arm__) || defined(__aarch64__)
#error This compatibility module is specific to Android 10 ARM32 bionic.
#endif
extern int pthread_mutex_destroy(void *mutex);
static unsigned char destroy_gate;
__attribute__((visibility("default")))
int g81_mnl_mutex_destroy(void *mutex) {
    if (!mutex) return 22; /* EINVAL */
    while (__atomic_test_and_set(&destroy_gate, __ATOMIC_ACQUIRE)) {
        __asm__ volatile("yield" ::: "memory");
    }
    unsigned short state = __atomic_load_n((unsigned short *)mutex, __ATOMIC_RELAXED);
    int result = state == 0xffff ? 0 : pthread_mutex_destroy(mutex);
    __atomic_clear(&destroy_gate, __ATOMIC_RELEASE);
    return result;
}
