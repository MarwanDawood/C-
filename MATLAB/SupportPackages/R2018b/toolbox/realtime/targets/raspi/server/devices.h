#ifndef _MW_DEVICES_H_
#define _MW_DEVICES_H_
#include "common.h"

typedef struct {
    int fd;
    char *name;
    int refCount;
} DEV_entry_t;

#define DEV_LED_0    (0)
#define DEV_GPIO_0   (1)
#define DEV_I2C_0    (33)
#define DEV_SPI_0    (35)
#define DEV_SERIAL_0 (37)

extern int DEV_getByName(const char *name);
extern int DEV_alloc(const char *name);
extern void DEV_free(const int devNo);
extern DEV_entry_t *DEV_get(const int id);
extern void DEV_init(void);
extern void DEV_lock(DEV_entry_t *dev);
extern void DEV_unlock(DEV_entry_t *dev);

#endif