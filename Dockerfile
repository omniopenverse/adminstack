# Dockerfile for the adminstack service
    # Ref: https://hub.docker.com/_/python/tags
FROM python:3.13.3-slim

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install --yes make \
        python3-pip \
        sshpass \
        curl \
        wget \
        jq \
        ssh \
        sudo \
        git \
        gh \
        vim \
        openssh-client \
        nfs-common \
        j2cli \
        ca-certificates \
        supervisor \
        iputils-ping \
        iproute2 \
        gnupg2 \
        bash-completion \
        software-properties-common \
        apt-transport-https \
        jupyter-notebook \
        gettext \
    && pip install --upgrade pip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install code-server
#   Ref: https://github.com/coder/code-server/releases
RUN curl -fsSL https://code-server.dev/install.sh | sh


# Install the latest release of kubectl
#   Ref: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-on-linux
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl* \
    && kubectl version --client \
    && mkdir ~/.kube

# Install Krew a kubectl plugin
#   Ref: https://krew.sigs.k8s.io/docs/user-guide/setup/install/
RUN cd "$(mktemp -d)" \
    && OS="$(uname | tr '[:upper:]' '[:lower:]')" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && KREW="krew-${OS}_${ARCH}" \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" \
    && tar zxvf "${KREW}.tar.gz" \
    && ./"${KREW}" install krew \
    && export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" \
    && kubectl krew install kc \
    && echo 'export PATH="/root/.krew/bin:$PATH"' >> /root/.bashrc

# Install KubeCm
#   Ref: https://kubecm.cloud/en-us/install?id=install
RUN VERSION=v0.27.1 \
    && curl -Lo kubecm.tar.gz https://github.com/sunny0826/kubecm/releases/download/${VERSION}/kubecm_${VERSION}_Linux_x86_64.tar.gz \
    && tar -zxvf kubecm.tar.gz kubecm && rm kubecm.tar.gz \
    && mv kubecm /usr/local/bin/

# Install k3sup
#   Ref: https://k3sup.dev/
RUN curl -sLS https://get.k3sup.dev | sh

# Add Docker's official GPG key, Add the repository to Apt sources and install Docker
#   Ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
RUN apt-get update \
    && apt-get install -y ca-certificates \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Install vscode-server extensions
#   Ref: https://marketplace.visualstudio.com/VSCode
RUN code-server --install-extension bierner.markdown-mermaid
                                    # ms-toolsai.jupyter

# Create a user for adminstack
RUN touch /var/log/adminstack.log \
    && useradd --home-dir /home/adminstack --groups sudo --create-home --shell /bin/bash adminstack \
    && mkdir -p /home/adminstack/.ssh /home/adminstack/.kube \
    && ssh-keygen -t rsa -b 2048 -q -N "" -f /home/adminstack/.ssh/id_rsa \
    && chmod 700 /home/adminstack/.ssh \
    && chown -R adminstack:adminstack /home/adminstack \
    && chown adminstack:adminstack /var/log/adminstack.log \
    && echo 'adminstack ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/adminstack \
    && echo 'adminstack:password' | chpasswd

WORKDIR /home/adminstack

# Set up github CLI
COPY --chown=adminstack:adminstack config/gh.sh /usr/local/bin/mygh
RUN chmod +x /usr/local/bin/mygh

# Set up supervisor
#   Ref: https://supervisord.org/
COPY --chown=adminstack:adminstack config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor /home/adminstack/.config/supervisor \
    && touch /var/log/supervisor/supervisord.log \
            /var/run/supervisord.pid \
            /var/run/sshd.pid \
    && chown -R adminstack:adminstack /var/run/sshd.pid \
    && chown -R adminstack:adminstack /var/log/supervisor \
    && chown adminstack:adminstack /var/run/supervisord.pid

# Set up ansible configuration
COPY config/ansible.cfg /etc/ansible/ansible.cfg

# Set up bash configuration
COPY --chown=adminstack:adminstack config/bash_fancy /home/adminstack/.bash_fancy
RUN echo "source ~/.bash_fancy" >> /home/adminstack/.bashrc

# Set up vscode configuration
COPY --chown=adminstack:adminstack config/vscode-settings.json /home/adminstack/.local/share/code-server/User/settings.json

# Copy ssh configuration
COPY --chown=adminstack:adminstack templates /home/adminstack/.config

# Set up entrypoint script
COPY --chown=adminstack:adminstack entrypoint.sh /entrypoint.sh

ENV LC_ALL="C.UTF-8"
ENV LANG="C.UTF-8"

RUN chown -R adminstack:adminstack /home/adminstack

USER adminstack

# EXPOSE 22 8080 8888

CMD ["bash", "/entrypoint.sh"]
