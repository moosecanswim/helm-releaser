FROM alpine/helm:3.4.2

ARG jq_version='1.6-r1'
ARG yq_version='2.11.1'
ARG sops_version='v3.6.1'

# Install required packages
RUN apk add --update --no-cache py-pip bash jq=${jq_version} && \
  pip install --no-cache-dir yq==${yq_version} awscli

# Install sops and prep scripts directory
RUN wget -O /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/${sops_version}/sops-${sops_version}.linux && \
  wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl && \
  wget -O /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator && \
  chmod 0755 /usr/local/bin/sops /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator && \
  mkdir /scripts /root/.kube

# Copy scripts
COPY ./scripts/* /scripts/

# Set permissions
RUN chmod -R +x /scripts/*

WORKDIR /release

ENTRYPOINT ["/scripts/release-manager.sh"]