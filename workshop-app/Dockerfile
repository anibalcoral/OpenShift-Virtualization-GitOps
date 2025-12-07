# Stage 1: Build frontend using Red Hat UBI
FROM registry.access.redhat.com/ubi9/nodejs-24:latest AS frontend-builder

USER 0

WORKDIR /frontend

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: Setup backend and final image using Red Hat UBI
FROM registry.access.redhat.com/ubi9/nodejs-24:latest

USER 0

RUN dnf install -y --allowerasing \
    bash \
    curl \
    git \
    vim-enhanced \
    python3 \
    python3-pip \
    make \
    gcc-c++ \
    ncurses \
    libevent \
    && dnf clean all

# Install tmuxp
RUN pip3 install --no-cache-dir tmuxp

WORKDIR /app

# Install Node.js backend
COPY server/package*.json ./
RUN npm ci --omit=dev

COPY server/server.js ./
COPY --from=frontend-builder /frontend/dist ./dist

RUN mkdir -p /app/guides

# Download OpenShift CLI (only oc, no kubectl)
RUN curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" && \
    tar -xzf openshift-client-linux.tar.gz -C /usr/local/bin oc && \
    rm openshift-client-linux.tar.gz && \
    chmod +x /usr/local/bin/oc

# Download virtctl CLI
RUN curl -L -o /usr/local/bin/virtctl "https://github.com/kubevirt/kubevirt/releases/download/v1.5.3/virtctl-v1.5.3-linux-amd64" && \
    chmod +x /usr/local/bin/virtctl

# Download and install static tmux binary
RUN curl -L -o /usr/local/bin/tmux "https://github.com/lgchiaretto/tmux/releases/download/v3.6/tmux.linux-amd64.stripped" && \
    chmod +x /usr/local/bin/tmux

# Copy clipboard helper script
COPY --chown=1001:0 tmux-config/clipboard-helper.sh /usr/local/bin/clipboard-helper
RUN chmod +x /usr/local/bin/clipboard-helper

# Copy tmux configuration files
COPY --chown=1001:0 tmux-config/tmux.conf /etc/skel/.tmux.conf
COPY --chown=1001:0 tmux-config/bashrc /etc/skel/.bashrc
COPY --chown=1001:0 tmux-config/vimrc /etc/skel/.vimrc
COPY --chown=1001:0 tmux-config/dircolors /etc/skel/.dircolors
COPY --chown=1001:0 tmux-config/inputrc /etc/skel/.inputrc
COPY --chown=1001:0 tmux-config/bash_functions /etc/skel/.bash_functions
COPY --chown=1001:0 tmux-config/plug.vim /etc/skel/.vim/autoload/plug.vim

# Setup user home with tmux config
RUN mkdir -p /home/default/.tmux /home/default/.vim/autoload /home/default/.ssh && \
    cp -r /etc/skel/.* /home/default/ 2>/dev/null || true && \
    chown -R 1001:0 /home/default && \
    chmod -R g=u /home/default && \
    chmod 700 /home/default/.ssh

# Configure Git globally
RUN git config --system user.name "Workshop User" && \
    git config --system user.email "workshop@gitops.local" && \
    git config --system init.defaultBranch main && \
    git config --system core.editor vim && \
    git config --system pull.rebase false

RUN chown -R 1001:0 /app && \
    chmod -R g=u /app

USER 1001

EXPOSE 8080

ENV PORT=8080
ENV GUIDES_DIR=/app/guides
ENV SHELL=/bin/bash
ENV HOME=/home/default

CMD ["node", "server.js"]
