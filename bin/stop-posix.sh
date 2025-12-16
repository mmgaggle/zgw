#!/bin/bash

if [[ $(podman ps -a -f status=running -f name=zgw-posix --format="{{.ID}}") ]] ; then
  podman kill zgw-posix
  podman rm zgw-posix
else
  echo "zgw-posix container is not running"
fi
