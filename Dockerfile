# MQ Client is required for Linux.  Go here to download: https://ibm.biz/mq93clients
# Needs to be placed in root of where Dockerfile exists

FROM cp.icr.io/cp/appc/ace:12.0.7.0-r1

ARG MQCLIENT_TARBALL=9.3.2.0-IBM-MQC-LinuxX64.tar.gz
ARG KEYSTORE_PASSWORD=changeit
ARG MQ_QUEUE_IN="IN.Q"
ARG MQ_QUEUE_OUT="OUT.Q"
ARG MQ_QMGR_NAME="QM1"
ARG MQ_HOST="MQ_HOST_NAME"
ARG MQ_PORT=443
ARG MQ_CHANNEL_NAME="EXTERNAL.SVRCONN"

ENV LICENSE=accept

COPY server.conf.yaml /home/aceuser/ace-server/overrides/server.conf.yaml
COPY trust.cer /home/aceuser/initial-config/keystore/trust.cer
COPY MQConnectproject.generated.bar /home/aceuser/initial-config/bar/MQConnectproject.generated.bar
COPY $MQCLIENT_TARBALL /tmp

USER root

RUN microdnf -y update \
    && microdnf -y upgrade \
    && microdnf install tar vi

RUN cd /tmp \
    && tar -zxvf $MQCLIENT_TARBALL \
    && cd /tmp/MQClient \
    && ./mqlicense.sh -accept \
    && rpm -ivh MQSeriesRuntime*.rpm MQSeriesJava*.rpm MQSeriesJRE*.rpm MQSeriesGSKit*.rpm MQSeriesClient*.rpm \
    && rm -Rf /tmp/$MQCLIENT_TARBALL /tmp/MQClient 

RUN /opt/mqm/bin/runmqckm -keydb -create -db /home/aceuser/initial-config/keystore/key -pw $KEYSTORE_PASSWORD -type cms -stash \
    && /opt/mqm/bin/runmqckm -cert -add -db /home/aceuser/initial-config/keystore/key.kdb -pw $KEYSTORE_PASSWORD -type cms -label ocp -file /home/aceuser/initial-config/keystore/trust.cer

RUN source /opt/ibm/ace-12/server/bin/mqsiprofile \
    && /opt/ibm/ace-12/server/bin/mqsiapplybaroverride -k MQConnect -b /home/aceuser/initial-config/bar/MQConnectproject.generated.bar -m MQ#MQInput.queueName=$MQ_QUEUE_IN,MQ#MQInput.destinationQueueManagerName=$MQ_QMGR_NAME,MQ#MQInput.queueManagerHostname=$MQ_HOST,MQ#MQInput.listenerPortNumber=$MQ_PORT,MQ#MQInput.channelName=$MQ_CHANNEL_NAME,MQ#MQOutput.queueName=$MQ_QUEUE_OUT,MQ#MQOutput.destinationQueueManagerName=$MQ_QMGR_NAME,MQ#MQOutput.queueManagerHostname=$MQ_HOST,MQ#MQOutput.listenerPortNumber=$MQ_PORT,Q#MQOutput.channelName=$MQ_CHANNEL_NAME \
    && /opt/ibm/ace-12/server/bin/mqsibar -a /home/aceuser/initial-config/bar/MQConnectproject.generated.bar -c -w /home/aceuser/ace-server

RUN chmod -R 755 /home/aceuser 

USER aceuser
