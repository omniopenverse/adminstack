# Ref: https://hub.docker.com/_/python/tags
FROM python:3.13.3-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install --yes make python3-pip sshpass curl jq ssh sudo \
        git vim openssh-client nfs-common j2cli supervisor gnupg2 && \
    pip install --upgrade pip && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN touch /var/log/admin.log \
    && useradd --home-dir /home/ansible --groups sudo --create-home --shell /bin/bash ansible \
    && mkdir -p /home/ansible/.ssh /home/ansible/.kube /home/ansible/data \
    && chown -R ansible:ansible /home/ansible \
    && echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/ansible \
    && echo 'ansible:ansible' | chpasswd

WORKDIR /home/ansible

# RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
#     && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
#     && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
#     && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
#     && kubectl version --client \
#     && mkdir ~/.kube

# Install Krew [https://krew.sigs.k8s.io/docs/user-guide/setup/install/] and KubeCm [https://kubecm.cloud/en-us/install?id=install]
# RUN cd "$(mktemp -d)" \
#     && OS="$(uname | tr '[:upper:]' '[:lower:]')" \
#     && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
#     && KREW="krew-${OS}_${ARCH}" \
#     && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" \
#     && tar zxvf "${KREW}.tar.gz" \
#     && ./"${KREW}" install krew \
#     && export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" \
#     && kubectl krew install kc \
#     && echo 'export PATH="/root/.krew/bin:$PATH"' >> /root/.bashrc

# Install KubeCm: [https://kubecm.cloud/en-us/install?id=install]
# RUN VERSION=v0.27.1 \
#     && curl -Lo kubecm.tar.gz https://github.com/sunny0826/kubecm/releases/download/${VERSION}/kubecm_${VERSION}_Linux_x86_64.tar.gz \
#     && tar -zxvf kubecm.tar.gz kubecm \
#     && mv kubecm /usr/local/bin/

# RUN curl -sLS https://get.k3sup.dev | sh
# RUN install k3sup /usr/local/bin/

COPY requirements/python.txt requirements/ansible.yml ./

RUN pip3 install -r python.txt && rm python.txt

USER ansible

RUN ansible-galaxy install -r ansible.yml && rm ansible.yml

USER root

COPY files/packages /home/ansible/packages
RUN pip3 install /home/ansible/packages/iaac_helper

USER ansible

# COPY templates/ssh_config.j2 ./
# RUN j2 requirements/ssh_config.j2 -o /home/ansible/.ssh/config \
#     && rm ssh_config.j2

COPY config/ansible.cfg /home/ansible/workplace/
COPY config/bash_fancy /home/ansible/.bash_fancy
RUN echo "source ~/.bash_fancy" >> /home/ansible/.bashrc

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22

# CMD ["tail", "-f", "/var/log/admin.log"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# ssh-keygen -t rsa -b 2048 -q -N "" -f /home/ansible/.ssh/id_rsa \
# cat /home/ansible/.ssh/id_rsa.pub >> /home/ansible/.ssh/authorized_keys
# sshpass -p ansible ssh-copy-id -i /home/ansible/.ssh/id_rsa.pub -o StrictHostKeyChecking=no ansible@localhost