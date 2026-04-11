#!/bin/sh
mfsmount /mnt/moosefs -f &
exec ttyd -W -p 7681 bash
