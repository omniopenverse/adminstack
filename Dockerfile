# Ref: https://hub.docker.com/_/python/tags
FROM python:3.13.3-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install --yes make python3-pip sshpass curl wget jq ssh sudo \
        git gh vim openssh-client nfs-common j2cli supervisor iputils-ping \
        iproute2 gnupg2 bash-completion software-properties-common \
        apt-transport-https jupyter-notebook gettext && \
    pip install --upgrade pip && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN curl -fsSL https://code-server.dev/install.sh | sh

RUN touch /var/log/admin.log \
    && useradd --home-dir /home/adminstack --groups sudo --create-home --shell /bin/bash adminstack \
    && mkdir -p /home/adminstack/.ssh /home/adminstack/.kube \
    && ssh-keygen -t rsa -b 2048 -q -N "" -f /home/adminstack/.ssh/id_rsa \
    && chmod 700 /home/adminstack/.ssh \
    && chown -R adminstack:adminstack /home/adminstack \
    && chown adminstack:adminstack /var/log/admin.log \
    && echo 'adminstack ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/adminstack \
    && echo 'adminstack:password' | chpasswd

WORKDIR /home/adminstack

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl* \
    && kubectl version --client \
    && mkdir ~/.kube

# Install Krew [https://krew.sigs.k8s.io/docs/user-guide/setup/install/]
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

# Install KubeCm: [https://kubecm.cloud/en-us/install?id=install]
RUN VERSION=v0.27.1 \
    && curl -Lo kubecm.tar.gz https://github.com/sunny0826/kubecm/releases/download/${VERSION}/kubecm_${VERSION}_Linux_x86_64.tar.gz \
    && tar -zxvf kubecm.tar.gz kubecm && rm kubecm.tar.gz \
    && mv kubecm /usr/local/bin/

RUN curl -sLS https://get.k3sup.dev | sh

COPY --chown=adminstack:adminstack requirements/python.txt requirements/ansible.yml ./

RUN pip3 install -r python.txt && rm python.txt \
    && python -m bash_kernel.install

USER adminstack

RUN ansible-galaxy install -r ansible.yml && rm ansible.yml \
    && sudo mkdir /etc/ansible

RUN code-server --install-extension bierner.markdown-mermaid

USER root

# COPY --chown=adminstack:adminstack files/packages /home/adminstack/packages
# RUN pip3 install /home/adminstack/packages/iaac_helper

COPY --chown=adminstack:adminstack config/gh.sh /usr/local/bin/mygh
RUN chmod +x /usr/local/bin/mygh

COPY --chown=adminstack:adminstack config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor /home/adminstack/.config/supervisor \
    && touch /var/log/supervisor/supervisord.log \
            /var/run/supervisord.pid \
            /var/run/sshd.pid \
    && chown -R adminstack:adminstack /var/run/sshd.pid \
    && chown -R adminstack:adminstack /var/log/supervisor \
    && chown adminstack:adminstack /var/run/supervisord.pid \
    && chown adminstack:adminstack /home/adminstack/.config/supervisor

USER adminstack

COPY config/ansible.cfg /etc/ansible/ansible.cfg
COPY --chown=adminstack:adminstack config/bash_fancy /home/adminstack/.bash_fancy
RUN echo "source ~/.bash_fancy" >> /home/adminstack/.bashrc

COPY --chown=adminstack:adminstack config/vscode-settings.json /home/adminstack/.local/share/code-server/User/settings.json
# COPY --chown=adminstack:adminstack config/vscode-settings.json /home/facko/.config/Code/User/settings.json

COPY --chown=adminstack:adminstack entrypoint.sh /entrypoint.sh

ENV LC_ALL="C.UTF-8"
ENV LANG="C.UTF-8"

EXPOSE 22 8080

# CMD ["tail", "-f", "/var/log/admin.log"]
CMD ["bash", "/entrypoint.sh"]

# ssh-keygen -t rsa -b 2048 -q -N "" -f /home/adminstack/.ssh/id_rsa \
# cat /home/adminstack/.ssh/id_rsa.pub >> /home/adminstack/.ssh/authorized_keys
# sshpass -p password ssh-copy-id -i /home/adminstack/.ssh/id_rsa.pub -o StrictHostKeyChecking=no adminstack@localhost

# COPY templates/ssh_config.j2 ./
# RUN j2 requirements/ssh_config.j2 -o /home/adminstack/.ssh/config \
#     && rm ssh_config.j2

# RUN apt update \
#     && apt install software-properties-common apt-transport-https wget -y \
#     && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
#     && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
#     && sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
#     && apt update \
#     && apt install code