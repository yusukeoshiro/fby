#!/bin/sh
dir1=force-app/main/default
fswatch -0 $dir1 -e "\\.git.*" | xargs -0 -n 1 -I{} ./upload.sh
