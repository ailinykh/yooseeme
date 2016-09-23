#ifndef _ELIAN_H_
#define _ELIAN_H_

#ifdef WIN32

#ifdef ELIAN_EXPORTS
#define ELIAN_API __declspec(dllexport)
#else
#define ELIAN_API __declspec(dllimport)
#endif

#else

#define ELIAN_API

#endif  //WIN32

enum etype_id {
	TYPE_ID_BEGIN = 0x0,
	TYPE_ID_AM,
	TYPE_ID_SSID,
	TYPE_ID_PWD,
	TYPE_ID_USER,
	TYPE_ID_PMK,
	TYPE_ID_CUST = 0x7F,
	TYPE_ID_MAX = 0xFF
};

//flag
#define ELIAN_SEND_V1	0x01
#define ELIAN_SEND_V4	0x02 //推荐

#ifdef __cplusplus
extern "C" {
#endif

//return context on success, NULL on fail
/*
 * 功能：获取当前库的版本号和协议的版本号
 * protoVersion 表示协议的版本号
 * libVersion 表示库的版本号
 */
ELIAN_API void elianGetVersion(int *protoVersion, int *libVersion);
    
/*
 * key 表示加密的密钥，可空
 * target 表示设备mac，NULL则表示针对所有设备
 * flag 表示协议，推荐使用ELIAN_SEND_V4
 */
ELIAN_API void *elianNew(const char *key, int keylen, const unsigned char *target, unsigned int flag);
    
ELIAN_API int elianPut(void *context, enum etype_id id, char *buf, int len);
ELIAN_API int elianStart(void *context);
ELIAN_API void elianStop(void *context);
ELIAN_API void elianDestroy(void *context);

#ifdef __cplusplus
};
#endif

#endif

