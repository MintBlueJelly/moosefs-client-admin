#!/bin/sh
mfsmount /mnt/moosefs -f &
exec ttyd -p 7681 bash
