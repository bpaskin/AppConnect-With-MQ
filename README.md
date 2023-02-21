#### Simple App Connect Enterprise with MQ Integration

This is a simple application that GETs messages from an MQ Queue and PUTs to another MQ Queue on the same host.  The connection is secured with SSL, and overrides are in the `Dockerfile`

#### REQUIRED:
[The MQ Client for Linux](https://ibm.biz/mq93clients) must be downloaded and kept in the same directory as the Dockerfile.  

The `ARG` values for the MQ Client and MQ information needs to be updated for the specific environment.

The `trust.cer` needs to be the trusted certificate for the targeted MQ QMGR

#### BUILD:
```
docker build -t ace -f Dockerfile .
````

#### RUN:
```
 docker run -d --name aceserver -p 7600:7600 -p 7800:7800 -p 7843:7843 --env LICENSE=accept --env ACE_SERVER_NAME=ACESERVER ace:latest
 ```
