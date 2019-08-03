FROM debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
    && apt-get install apt-utils -qq 

RUN apt-get install -qq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    file \
    ftp \
    jq \
    git \
    gnupg \
    iproute2 \
    iputils-ping \
    locales \
    lsb-release \
    netcat \
    sudo \
    time \
    unzip \
    wget \
    zip \
&& rm -rf /var/lib/apt/lists/* && apt-get clean

# Install dotnet sdk
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
    && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
    && wget -q https://packages.microsoft.com/config/debian/9/prod.list \
    && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update \
    && apt-get -y install dotnet-sdk-2.1 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /etc/apt/sources.list.d/* \
    && apt-get clean

ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip

# Accept the TEE EULA
RUN mkdir -p "/root/.microsoft/Team Foundation/4.0/Configuration/TEE-Mementos" \
 && cd "/root/.microsoft/Team Foundation/4.0/Configuration/TEE-Mementos" \
 && echo '<ProductIdData><eula-14.0 value="true"/></ProductIdData>' > "com.microsoft.tfs.client.productid.xml"

# Install Docker
ENV DOCKER_VERSION 18.06.3-ce
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz \
    && tar --strip-components=1 -xvzf docker-$DOCKER_VERSION.tgz -C /usr/local/bin && rm docker-$DOCKER_VERSION.tgz

# Install Kubectl
ENV KUBE_VERSION 1.14.4
RUN curl -fsSLO https://storage.googleapis.com/kubernetes-release/release/v$KUBE_VERSION/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin && chmod 755 /usr/local/bin/kubectl

# Install terraform
ENV TERRAFORM_VERSION 0.12.6
RUN curl -fsSLO https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && chmod 755 /usr/local/bin/terraform && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

WORKDIR /vsts

COPY ./start.sh .
RUN chmod +x start.sh

ENV VSTS_AGENT='$(hostname)-agent'
ENV VSTS_WORK='/var/vsts/$VSTS_AGENT'

CMD ["./start.sh"]