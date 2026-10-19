// G81 engineering probe: exact PQ 2.0 HIDL wire methods from the stock proxy.
#include <hidl/HidlTransportSupport.h>
#include <hidl/ServiceManagement.h>
#include <hidl/HidlBinderSupport.h>
#include <hwbinder/Parcel.h>
#include <hwbinder/IBinder.h>
#include <android/hidl/manager/1.0/IServiceManager.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
using namespace android;
static const char* descriptor="vendor.mediatek.hardware.pq@2.0::IPictureQuality";
int main(int argc,char**argv) {
    if(argc<3 || (strcmp(argv[1],"get") && strcmp(argv[1],"set"))) {
        fprintf(stderr,"usage: g81-pqctl get FEATURE | set FEATURE VALUE\n"); return 2;
    }
    unsigned id=strtoul(argv[2],nullptr,10); if(id>11) return 2;
    bool set=!strcmp(argv[1],"set"); if(set && argc!=4) return 2;
    auto manager=hardware::defaultServiceManager(); if(!manager){ puts("NO_MANAGER"); return 3; }
    sp<hidl::base::V1_0::IBase> service;
    // init publishes running before HAL registration; wait for the actual service.
    for(int attempt=0; attempt<100 && !service; ++attempt) {
        auto ret=manager->get(descriptor,"default");
        if(!ret.isOk()){ puts("GET_SERVICE_TRANSPORT_ERROR"); return 4; }
        service=ret; if(!service) usleep(100000);
    }
    if(!service){ puts("NO_PQ_SERVICE"); return 5; }
    auto binder=hardware::getOrCreateCachedBinder(service.get());
    hardware::Parcel request,reply;
    request.writeInterfaceToken(descriptor);
    request.writeInt32(static_cast<int32_t>(id));
    if(set) request.writeUint32(strtoul(argv[3],nullptr,10));
    // Stock BpHwPictureQuality: setFeatureSwitch=12, getFeatureSwitch=13.
    int transport=binder->transact(set?12:13,request,&reply,0);
    hardware::Status status; int parse=hardware::readFromParcel(&status,reply);
    if(transport || parse || !status.isOk()) {
        printf("TRANSPORT_ERROR rc=%d parse=%d status=%s\n",transport,parse,status.description().c_str()); return 6;
    }
    int32_t result=0; if(reply.readInt32(&result)){ puts("RESULT_READ_ERROR"); return 7; }
    if(set) { printf("SET feature=%u result=%d\n",id,result); return result==0?0:8; }
    uint32_t value=0; if(reply.readUint32(&value)){ puts("VALUE_READ_ERROR"); return 9; }
    printf("GET feature=%u result=%d value=%u\n",id,result,value);
    return result==0?0:8;
}
