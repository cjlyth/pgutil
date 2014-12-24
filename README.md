pgutil
======
Scripts to help develop with docker containers at work

This script is currently the only entrypoint

```shell
run.sh
```


Optionally increase the base container size:

`cat /etc/default/docker`

```
DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --storage-opt dm.basesize=50G"
```
