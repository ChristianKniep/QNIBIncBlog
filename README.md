# qnib.org blog

## Build

Build will create a docker image holding the static website and copies the website out to `_site`.

```bash
./build.sh
```

## Publish

To backup the old website (for safety reasons):

```bash
aws s3 cp --recursive s3://<s3-bucket> ~/backup/qnib-www-$(date +%F)
```

Afterwards we can just sync the result into the target bucket.

```bash
aws s3 sync _site/ s3://<s3-bucket>/
```