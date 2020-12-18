FROM alpine/helm:3.4.2

ARG jq_version='1.6-r1'
ARG yq_version='2.11.1'
ARG sops_version='v3.6.1'

# Install required packages
RUN apk add --update --no-cache py-pip bash jq=${jq_version} && \
  pip install --no-cache-dir yq==${yq_version} awscli

# Install sops and prep scripts directory
RUN wget -O /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/${sops_version}/sops-${sops_version}.linux && \
  chmod 0755 /usr/local/bin/sops && \
  mkdir /scripts

# Copy scripts
COPY ./scripts/* /scripts/

# Set permissions
RUN chmod -R +x /scripts/*

WORKDIR /release

ENTRYPOINT ["/scripts/release-manager.sh"]