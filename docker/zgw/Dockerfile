FROM quay.io/ceph/ceph:v19.2.3-20250717

USER root
COPY config /etc/ceph/ceph.conf
RUN chown ceph:ceph /etc/ceph/ceph.conf
RUN mkdir -p /var/lib/ceph/radosgw/{db,buckets}
RUN chown ceph:ceph -R /var/lib/ceph/radosgw

RUN curl -LO https://github.com/peak/s5cmd/releases/download/v2.0.0/s5cmd_2.0.0_Linux-64bit.tar.gz 
RUN curl -LO https://github.com/minio/warp/releases/download/v0.6.2/warp_0.6.2_Linux_x86_64.tar.gz
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN tar xvzf s5cmd_2.0.0_Linux-64bit.tar.gz
RUN tar xvzf warp_0.6.2_Linux_x86_64.tar.gz
RUN unzip awscliv2.zip
RUN mv s5cmd /usr/local/bin/
RUN mv warp /usr/local/bin/
RUN ./aws/install
COPY entrypoint.sh /opt/ceph-container/bin/
