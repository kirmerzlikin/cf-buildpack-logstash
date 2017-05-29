# Precompile

To reduce the compile phase during `cf push` the curator package with all its dependencies (python, libraries) could be packed to a tar archive and made available for download, for example on S3. To create or update the tar archive, the following steps have to be performed:

Precoditions:

* Have cf point to the right end point and have a valid session (logged in to cf)
* Install `sshpass` and `jq` if not yet present on your workstation (e.g. `apt-get install sshpass jq`).
* Install `mc` (minio client), download https://dl.minio.io/client/mc/release/linux-amd64/mc
* Properly configured minio client to access the S3 bucket

1. Deploy a Logstash app to cf with `CURATOR_COMPILE=1` set in the `Logstash` control file.
2. Login to the deployed app with `cf ssh APP_NAME -i 0`
3. Run the following commands:

```
cd app
tar czf curator-5.0.4-python-3.6.1.tar.gz curator python3
```

4. From your workstation (tested on Linux) run the following commands:


```
sshpass -p $(cf ssh-code) scp -P 2222 -o "User cf:$(cf app logstash --guid)/0" $(cf target | grep "API endpoint" | awk ' { gsub(/https?:\/\//, "", $3); print $3 } '):app/curator-5.0.4-python-3.6.1.tar.gz .
```

5. Copy archive file to S3

```
mc cp ~/tmp/python/tmp/curator-5.0.4-python-3.6.1.tar.gz S3_HOST_ALIAS/logstash-buildpack
```

6. Create download link valid for ~10 years

Save the following content to a script (add mc_host_alias and fileName) and run it (script also present in `scripts/generate_10_years_link.sh`.

```
#!/bin/bash
urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}

mc_host_alias="S3_HOST_ALIAS"
host=$(cat ~/.mc/config.json | jq -r ".hosts.\"${mc_host_alias}\".url")
bucket="logstash-buildpack"
s3Key=$(cat ~/.mc/config.json | jq -r ".hosts.\"${mc_host_alias}\".accessKey")
s3Secret=$(cat ~/.mc/config.json | jq -r ".hosts.\"${mc_host_alias}\".secretKey")
fileName="curator-5.0.4-python-3.6.1.tar.gz"
resource="/${bucket}/${fileName}"
expiryDate=$(echo "$(date +%s) + 315360000" |bc)
s3KeyEnc=$(urlencode $s3Key)
stringToSign="GET\n\n\n${expiryDate}\n${resource}"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
signatureEnc=$(urlencode $signature)

url="${host}/${bucket}/${fileName}?AWSAccessKeyId=${s3KeyEnc}&Expires=${expiryDate}&Signature=${signatureEnc}"
echo $url
```

7. Add the returned URL from step 6 to bin/compile on the line starting with `CURATOR_PRECOMPILED=`