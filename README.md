# Z is for zipper: S3 gateway

zgw-dbstore is a light weight S3 server dialect based on the Ceph object
gateway that persists objects and metadata into a SQLite database. If you've
ever wanted to use Ceph's object gateway, without deploying a cluster, this is
for you!

The Ceph object gateway has conventionally carried the name radosgw, or rgw for
short. [RADOS](https://ceph.com/assets/pdfs/weil-rados-pdsw07.pdf) is Ceph's
native object storage system. Sans RADOS, the radosgw is the /zgw/.

This was made possible by the Zipper initiative, which introduced a layering API
based on stackable modules/drivers, similar to Unix filesystems (VFS). A number
of store drivers SALs exist already:

* [DBstore](https://github.com/ceph/ceph/tree/main/src/rgw/store/dbstore) - Reference implementation
* [cortx-rgw](https://github.com/Seagate/cortx-rgw) for [Seagate CORTX](https://github.com/Seagate/cortx)
* [daos](https://github.com/ceph/ceph/pull/47709) for [Intel DAOS](https://github.com/daos-stack/daos)
* [sfs](https://github.com/aquarist-labs/ceph/tree/s3gw/src/rgw/store/sfs) for [SUSE s3gw](https://github.com/aquarist-labs/s3gw-tools/)

This repository is intended to provide tooling to build container images for
the Ceph object gateway with the dbstore store driver and POSIX filter driver.

# Kubernetes Deployments

## minikube zgw-dbstore

### Create zgw-dbstore resources

```
kubectl apply -f examples/openshift/zgw-dbstore.yaml
```

### Create toolbox resources

The toolbox includes pre-configured CLI tools to interact with zgw-dbstore:

* s5cmd: blazing fast s3 client
* warp: s3 benchmarking utility

To create a toolbox pod, use:

```
kubectl apply -f examples/openshift/zgw-toolbox.yaml
```

### Enter zgw-toolbox pod

```
TOOLBOX_ID=$(kubectl get po | grep toolbox | awk '{print $1}')
kubectl exec --stdin --tty ${TOOLBOX_ID} -- /bin/bash
```

### Using s5cmd

The container entrypoint sets up credentials for s5cmd.

```
s5cmd --endpoint-url http://s3.default.svc.cluster.local \
  mb s3://mybucket
```

Grab some sample data and upload it.

```
cd /tmp
curl -LO https://d37ci6vzurychx.cloudfront.net/misc/taxi+_zone_lookup.csv
s5cmd --endpoint-url http://s3.default.svc.cluster.local \
  cp taxi+_zone_lookup.csv s3://mybucket
```

### Query sample CSV object with S3 Select
```
aws s3api select-object-content \
  --endpoint-url http://s3.default.svc.cluster.local \
  --bucket 'mybucket' \
  --key 'taxi+_zone_lookup.csv' \
  --expression "SELECT * FROM S3Object s where s._2='\"Brooklyn\"'" \
  --expression-type 'SQL' \
  --input-serialization '{"CSV": {"FieldDelimiter": ",","RecordDelimiter": "\n" ,  "FileHeaderInfo": "IGNORE" }}' \
  --output-serialization '{"CSV": {"FieldDelimiter": ":"}}' /dev/stdout
```

### Run warp benchmark
```
warp put --host s3.default.svc.cluster.local:80 \
  --access-key zippy \
  --secret-key zippy \
  --duration 15s
```

## minikube zgw-posix

The POSIX filter driver provides a POSIX filesystem interface on top of dbstore.

### Create zgw-posix resources

```
kubectl apply -f examples/openshift/zgw-posix.yaml
```

This creates:
- Three PersistentVolumeClaims (for POSIX driver data, database, and radosgw store)
- A deployment running the zgw-posix container
- A service exposing S3 API on port 80

### Access zgw-posix

The service is available at `http://s3-posix.default.svc.cluster.local` within the cluster.

You can use the same toolbox and s5cmd commands as with zgw-dbstore, just update the endpoint:

```
s5cmd --endpoint-url http://s3-posix.default.svc.cluster.local mb s3://mybucket
```

# Podman Deployments

## podman zgw-dbstore

Set environmental variables if you want to override the default set of
credentials for the `zippy` user.

```
podman run -it zgw-dbstore:latest \
  -v /mnt:/var/lib/ceph/radosgw \
  -p 7480:7480 \
  -e COMPONENT=zgw-dbstore \
  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-zippy} \
  -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-zippy}
```

Or use the helper scripts in the `bin/` directory:

```
# Start zgw-dbstore container
./bin/start.sh

# Restart zgw-dbstore container
./bin/restart.sh

# Stop zgw-dbstore container
./bin/stop.sh
```

## podman zgw-posix

The POSIX filter driver adds a POSIX filesystem layer on top of dbstore, allowing
objects to be accessed via both S3 API and POSIX filesystem operations.

Set environmental variables if you want to override the default set of
credentials for the `zippy` user and customize storage paths and the port to
listen on.

```
mkdir ~/posix ; mkdir ~/db ; mkdir ~/store 

podman run -d \
  -v ~/posix:/var/lib/ceph/rgw_posix_driver:rw,Z \
  -v ~/db:/var/lib/ceph/rgw_posix_db:rw,Z \
  -v ~/store:/var/lib/ceph/radosgw:rw,Z \
  -e COMPONENT=zgw-posix \
  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-zippy} \
  -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-zippy} \
  -e RGW_POSIX_BASE_PATH=/var/lib/ceph/rgw_posix_driver \
  -e RGW_POSIX_DATABASE_ROOT=/var/lib/ceph/rgw_posix_db \
  -p 9090:7480 \
  zgw-posix:latest

$ cat .aws/credentials
[zipy]
aws_access_key_id = zippy
aws_secret_access_key = zippy

$ aws --profile zipy --endpoint http://localhost:9090 s3 mb s3://bucket --region default
$ aws --profile zipy --endpoint http://localhost:9090 s3 cp /etc/hosts s3://bucket/ok --region default
upload: ../../etc/hosts to s3://bucket/ok
```

You can also use the helper scripts in the `bin/` directory:

```
# Start zgw-posix container
./bin/start-posix.sh

# Restart zgw-posix container
./bin/restart-posix.sh

# Stop zgw-posix container
./bin/stop-posix.sh
```

# Building containers

## Building zgw:dbstore container

```
docker build -t zgw-dbstore docker/zgw-dbstore
```

## Building zgw:posix container

```
docker build -t zgw-posix docker/zgw-posix
```
