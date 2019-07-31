FROM microsoft/vsts-agent

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Update packages and install new ones
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && apt-get update \
  && apt-get install docker-ce apt-utils unzip -qq \
  && apt-get clean 

# Set env variables
ENV VSTS_AGENT='$(hostname)-agent'
ENV VSTS_WORK='/var/vsts/$VSTS_AGENT'

CMD ["./start.sh"]