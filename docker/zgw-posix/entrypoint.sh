#!/bin/bash
set -euo pipefail

# Ensure ceph.conf is writable (helpful in restrictive runtimes like OpenShift)
chown ceph:ceph /etc/ceph/ceph.conf || true

# Default component if none supplied
COMPONENT=${COMPONENT:-zgw-posix}

########################################
# Helpers                              #
########################################
ensure_paths() {
  # Create POSIX driver directories so LMDB init won’t abort
  mkdir -p "${RGW_POSIX_BASE_PATH}" \
           "${RGW_POSIX_DATABASE_ROOT}" \
           "${RGW_POSIX_DATABASE_ROOT}/rgw_posix_lmdbs"
  chown -R ceph:ceph "${RGW_POSIX_BASE_PATH}" "${RGW_POSIX_DATABASE_ROOT}" || true
}

add_posix_config() {
  if ! grep -q "rgw filter" /etc/ceph/ceph.conf; then
    cat <<EOF > /etc/ceph/ceph.conf
[client]
    rgw backend store = dbstore
    rgw config store  = dbstore
    rgw filter        = posix
EOF
  fi
  # Inject runtime‑selectable paths
  sed -i "/rgw filter/a \    rgw_posix_base_path = ${RGW_POSIX_BASE_PATH}" /etc/ceph/ceph.conf
  sed -i "/rgw_posix_base_path/a \    rgw_posix_database_root = ${RGW_POSIX_DATABASE_ROOT}" /etc/ceph/ceph.conf
}

create_default_user() {
  ensure_paths
  if ! radosgw-admin user info --uid=zippy &>/dev/null; then
    # Don’t fail container start if this command errors
    set +e
    radosgw-admin user create \
      --uid zippy \
      --display-name zippy \
      --access-key "${AWS_ACCESS_KEY_ID:-zippy}" \
      --secret-key "${AWS_SECRET_ACCESS_KEY:-zippy}"
    set -e
  fi
}

########################################
# Component dispatch                   #
########################################
case "${COMPONENT}" in
  zgw-posix|zgw-dbstore)
    add_posix_config
    create_default_user

    exec /usr/bin/radosgw \
      --cluster ceph \
      --setuser ceph \
      --setgroup ceph \
      --default-log-to-stderr=true \
      --err-to-stderr=true \
      --default-log-to-file=false \
      --foreground \
      -n client.rgw \
      --no-mon-config
    ;;
  zgw-toolbox)
    echo "Toolbox container — sleeping indefinitely"
    exec sleep infinity
    ;;
  *)
    # Any other command: just run it
    exec "$@"
    ;;
esac

