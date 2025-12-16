#!/bin/bash

# Configurable data paths - override these by setting environment variables
ZGW_POSIX_PATH=${ZGW_POSIX_PATH:-${HOME}/posix}
ZGW_DB_PATH=${ZGW_DB_PATH:-${HOME}/db}
ZGW_STORE_PATH=${ZGW_STORE_PATH:-${HOME}/store}
ZGW_POSIX_PORT=${ZGW_POSIX_PORT:-9090}

# Create directories if they don't exist
[ -d "${ZGW_POSIX_PATH}" ] || mkdir -p ${ZGW_POSIX_PATH}
[ -d "${ZGW_DB_PATH}" ] || mkdir -p ${ZGW_DB_PATH}
[ -d "${ZGW_STORE_PATH}" ] || mkdir -p ${ZGW_STORE_PATH}

run_zgw_posix () {
  podman run --name zgw-posix \
           -v ${ZGW_POSIX_PATH}:/var/lib/ceph/rgw_posix_driver:rw,Z \
           -v ${ZGW_DB_PATH}:/var/lib/ceph/rgw_posix_db:rw,Z \
           -v ${ZGW_STORE_PATH}:/var/lib/ceph/radosgw:rw,Z \
           -e COMPONENT=zgw-posix \
           -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-zippy} \
           -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-zippy} \
           -e RGW_POSIX_BASE_PATH=/var/lib/ceph/rgw_posix_driver \
           -e RGW_POSIX_DATABASE_ROOT=/var/lib/ceph/rgw_posix_db \
           -p ${ZGW_POSIX_PORT}:7480 \
           -d zgw-posix:latest
}

if [[ $(podman ps -a -f status=running -f name=zgw-posix --format="{{.ID}}") ]] ; then
  podman kill zgw-posix
  podman rm zgw-posix
  run_zgw_posix
else
  echo "zgw-posix container is not running, starting"
  run_zgw_posix
fi
