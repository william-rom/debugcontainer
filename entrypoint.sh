#!/bin/sh
if [ "$#" -gt 0 ]; then
    exec "$@"
elif [ -t 0 ]; then
    exec /bin/bash
else
    exec sleep infinity
fi
