#!/bin/sh


set -e
#sudo dockerd --insecure-registry=172.19.0.7:5000
echo "starting dockerd..."
sudo dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --insecure-registry=172.19.0.3:5000 --storage-driver=vfs &
echo "starting jnlp slave..."
exec java -jar /usr/share/jenkins/slave.jar \
	-jnlpUrl $JENKINS_URL/computer/$JENKINS_SLAVE_NAME/slave-agent.jnlp \
	-secret $JENKINS_SLAVE_SECRET
	
	
