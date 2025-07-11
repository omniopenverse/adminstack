# Ref: https://hub.docker.com/_/python/tags
FROM python:3.13.3-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install --yes make python3-pip sshpass curl jq ssh sudo \
        git vim openssh-client nfs-common j2cli supervisor iputils-ping \
        iproute2 gnupg2 bash-completion && \
    pip install --upgrade pip && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN touch /var/log/admin.log \
    && useradd --home-dir /home/adminstack --groups sudo --create-home --shell /bin/bash adminstack \
    && mkdir -p /home/adminstack/.ssh /home/adminstack/.kube /home/adminstack/data \
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
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
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
    && tar -zxvf kubecm.tar.gz kubecm \
    && mv kubecm /usr/local/bin/

RUN curl -sLS https://get.k3sup.dev | sh

COPY requirements/python.txt requirements/ansible.yml ./

RUN pip3 install -r python.txt && rm python.txt \
    && python -m bash_kernel.install

USER adminstack

RUN ansible-galaxy install -r ansible.yml && rm ansible.yml

USER root

COPY files/packages /home/adminstack/packages
RUN pip3 install /home/adminstack/packages/iaac_helper

USER adminstack

# COPY templates/ssh_config.j2 ./
# RUN j2 requirements/ssh_config.j2 -o /home/adminstack/.ssh/config \
#     && rm ssh_config.j2

COPY config/ansible.cfg /home/adminstack/
COPY config/bash_fancy /home/adminstack/.bash_fancy
RUN echo "source ~/.bash_fancy" >> /home/adminstack/.bashrc

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV LC_ALL="C.UTF-8"
ENV LANG="C.UTF-8"

EXPOSE 22

# CMD ["tail", "-f", "/var/log/admin.log"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# ssh-keygen -t rsa -b 2048 -q -N "" -f /home/adminstack/.ssh/id_rsa \
# cat /home/adminstack/.ssh/id_rsa.pub >> /home/adminstack/.ssh/authorized_keys
# sshpass -p password ssh-copy-id -i /home/adminstack/.ssh/id_rsa.pub -o StrictHostKeyChecking=no adminstack@localhost