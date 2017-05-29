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