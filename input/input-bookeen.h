#ifndef _KO_INPUT_BOOKEEN_H
#define _KO_INPUT_BOOKEEN_H

#define USBPLUG_DEVPATH "/devices/platform/usb_plug"
#define USBHOST_DEVPATH "/devices/platform/usb_host"

#include "libue.h"

// NOTE: We don't generate any fake events on Bookeen (no USB/charging uevent handling yet),
//       but input.c still forks this off unconditionally, so it has to exist.
static void generateFakeEvent(int pipefd[2] __attribute__((unused))) {
  return;
}


#endif
