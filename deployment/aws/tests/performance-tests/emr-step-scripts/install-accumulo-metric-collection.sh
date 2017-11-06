#!/bin/bash -xe

GAFFER_TOOLS_VERSION=""
ACCUMULO_INSTANCE=""
WAIT_HANDLE_URL=""

INSTALL_DIR=/opt/accumulo-metrics

MAVEN_VERSION=3.5.0
MAVEN_DOWNLOAD_URL=https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		-i|--accumulo-instance)
			ACCUMULO_INSTANCE=$2
			shift
			;;
		-w|--wait-handle-url)
			WAIT_HANDLE_URL=$2
			shift
			;;
		*)
			GAFFER_TOOLS_VERSION=$1
			;;
	esac
	shift
done

if [[ "$WAIT_HANDLE_URL" ]]; then
	function awsSignal {
		/opt/aws/bin/cfn-signal -e $? "$WAIT_HANDLE_URL"
	}
	trap awsSignal EXIT
fi

if [[ "$GAFFER_TOOLS_VERSION" == "" || "$ACCUMULO_INSTANCE" == "" ]]; then
	echo "Usage: $0 <gafferToolsVersion> -i <accumuloInstance> [-w <awsWaitHandleUrl>]"
	exit 1
fi

function install_dev_tools {
	# Install git
	if ! which git >/dev/null 2>&1; then
		sudo yum install -y git
	fi

	# Install Apache Maven
	if ! which mvn >/dev/null 2>&1; then
		echo "Downloading Apache Maven $MAVEN_VERSION from $MAVEN_DOWNLOAD_URL"
		curl -fLO $MAVEN_DOWNLOAD_URL
		tar -xf apache-maven-$MAVEN_VERSION-bin.tar.gz
		rm -f apache-maven-$MAVEN_VERSION-bin.tar.gz
		export PATH=$PWD/apache-maven-$MAVEN_VERSION/bin:$PATH
	fi
}

sudo mkdir -p $INSTALL_DIR

# Work out if we can download performance-testing-aws.jar or if we need to build it from source...
if ! curl -fLO https://repo1.maven.org/maven2/uk/gov/gchq/gaffer/performance-testing-aws/$GAFFER_TOOLS_VERSION/performance-testing-aws-$GAFFER_TOOLS_VERSION-full.jar; then
	echo "Building Gaffer performance-testing-aws.jar from branch $GAFFER_TOOLS_VERSION..."
	install_dev_tools
	git clone -b $GAFFER_TOOLS_VERSION --depth 1 https://github.com/gchq/gaffer-tools.git
	cd gaffer-tools
	mvn clean package -Pquick -pl performance-testing/performance-testing-aws --also-make
	GAFFER_TOOLS_POM_VERSION=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)
	echo "Detected Gaffer Tools version as $GAFFER_TOOLS_POM_VERSION"

	sudo cp ./performance-testing/performance-testing-aws/target/performance-testing-aws-$GAFFER_TOOLS_POM_VERSION-full.jar $INSTALL_DIR/

	# Tidy up
	cd ..
	rm -rf gaffer-tools
else
	echo "Using Gaffer performance-testing-aws.jar from Maven Central..."
	GAFFER_TOOLS_POM_VERSION=$GAFFER_TOOLS_VERSION
	sudo mv ./performance-testing-aws-$GAFFER_TOOLS_POM_VERSION-full.jar $INSTALL_DIR/
fi

JAR_PATH=$INSTALL_DIR/performance-testing-aws-$GAFFER_TOOLS_POM_VERSION-full.jar

# Set up as a system service
sudo tee /etc/init/accumulo-metrics.conf <<EOF
description "Accumulo Metrics Collector"

start on runlevel [345]
stop on runlevel [0126]

respawn
respawn limit 10 60

env LOG_DIR=/var/log/accumulo-metrics

pre-start exec mkdir -p \$LOG_DIR

exec /usr/bin/java \\
	-cp $JAR_PATH \\
	uk.gov.gchq.gaffer.performancetesting.aws.PublishAccumuloMetricsToCloudWatch \\
	$ACCUMULO_INSTANCE \\
	localhost \\
	>>\$LOG_DIR/out.log \\
	2>>\$LOG_DIR/err.log

EOF

sudo start accumulo-metrics
