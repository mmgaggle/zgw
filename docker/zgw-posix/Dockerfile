FROM quay.ceph.io/ceph-ci/ceph:main

USER root

COPY ceph.conf /etc/ceph/ceph.conf
RUN chown ceph:ceph /etc/ceph/ceph.conf \
    && chown -R ceph:ceph /var/lib/ceph/radosgw

ENV RGW_POSIX_BASE_PATH=/var/lib/ceph/rgw_posix_driver \
    RGW_POSIX_DATABASE_ROOT=/var/lib/ceph/rgw_posix_db

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
