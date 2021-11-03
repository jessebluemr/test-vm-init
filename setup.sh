# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common

# docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# for pupetteer (https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#running-puppeteer-in-docker)
# also add additional libs: https://github.com/puppeteer/puppeteer/blob/main/.ci/node12/Dockerfile.linux
curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
add-apt-repository "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"

# for kubectl
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main"

apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        git \
        graphviz \
        docker-ce docker-ce-cli containerd.io \
        kubectl \
        liblttng-ust0 \
        iputils-ping \
        libcurl4 \
        libunwind8 \
        netcat \
        libssl1.0 \
        zip \
        unzip \
        # for pupetteer
        google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libx11-xcb1 libxcb1


# install Azure CLI and dependencies
curl -LsS https://aka.ms/InstallAzureCLIDeb | bash

# remove apt lists
#apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# install maven (need to update if new maven version is available)
MAVEN_VERSION="3.8.3"
MAVEN_HOME=/usr/share/maven
curl -LfsSo /tmp/maven.tar.gz https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && mkdir -p $MAVEN_HOME \
    && tar -xzC $MAVEN_HOME --strip-components=1 -f /tmp/maven.tar.gz \
    && rm /tmp/maven.tar.gz \
    && ln -s $MAVEN_HOME/bin/mvn /usr/bin/mvn

# See for possible downloads https://adoptium.net/releases.html?variant=openjdk11&jvmVariant=hotspot
# Update the links to ensure newer jdk patch versions are included
# See for envs for jdk these vars of common microsoft vm-agent pattern, see https://github.com/actions/virtual-environments/blob/main/images/linux/Ubuntu2004-README.md#java

# Install java 17
JAVA_HOME_17_X64=/usr/share/openjdk17
curl -LfsSo /tmp/openjdk17.tar.gz https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17%2B35/OpenJDK17-jdk_x64_linux_hotspot_17_35.tar.gz \
    && mkdir -p $JAVA_HOME_17_X64 \
    && tar -xzC $JAVA_HOME_17_X64 --strip-components=1 -f /tmp/openjdk17.tar.gz \
    && rm /tmp/openjdk17.tar.gz

# Install java 11
JAVA_HOME_11_X64=/usr/share/openjdk11
curl -LfsSo /tmp/openjdk11.tar.gz https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.12%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.12_7.tar.gz \
    && mkdir -p $JAVA_HOME_11_X64 \
    && tar -xzC $JAVA_HOME_11_X64 --strip-components=1 -f /tmp/openjdk11.tar.gz \
    && rm /tmp/openjdk11.tar.gz

# Install java 8
JAVA_HOME_8_X64=/usr/share/openjdk8
curl -LfsSo /tmp/openjdk8.tar.gz https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u302-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u302b08.tar.gz \
    && mkdir -p $JAVA_HOME_8_X64 \
    && tar -xzC $JAVA_HOME_8_X64 --strip-components=1 -f /tmp/openjdk8.tar.gz \
    && rm /tmp/openjdk8.tar.gz

# integrate internal root cert of con terra
# COPY ConterraRootCA.crt /root/ConterraRootCA.crt
# RUN $JAVA_HOME_8_X64/bin/keytool -importcert -noprompt -keystore "$JAVA_HOME_8_X64/jre/lib/security/cacerts" -storepass changeit -alias ConterraRootCA -file /root/ConterraRootCA.crt \
#    && $JAVA_HOME_11_X64/bin/keytool -importcert -noprompt -cacerts -storepass changeit -alias ConterraRootCA -file /root/ConterraRootCA.crt \
#    && $JAVA_HOME_17_X64/bin/keytool -importcert -noprompt -cacerts -storepass changeit -alias ConterraRootCA -file /root/ConterraRootCA.crt

# write env vars (need to modify /etc/environment because azure dev ops is trigger '/bin/bash --noprofile --norc')
echo "export JAVA_HOME=$JAVA_HOME_11_X64"         >> /etc/environment
echo "export JAVA_HOME_8_X64=$JAVA_HOME_8_X64"    >> /etc/environment
echo "export JAVA_HOME_11_X64=$JAVA_HOME_11_X64"  >> /etc/environment
echo "export JAVA_HOME_17_X64=$JAVA_HOME_17_X64"  >> /etc/environment
echo "export MAVEN_VERSION=$MAVEN_VERSION"        >> /etc/environment
echo "export MAVEN_HOME=$MAVEN_HOME"              >> /etc/environment

# add azure devops user 'AzDevOps'
set -eux \
    && groupadd --gid 10000 -r vsts \
    && useradd --uid 10000 -r -g vsts -G docker AzDevOps \
    && mkdir -p /home/AzDevOps/.m2/repository \
    && chown -R AzDevOps:vsts /home/AzDevOps
