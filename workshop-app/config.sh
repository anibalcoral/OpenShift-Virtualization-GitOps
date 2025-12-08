#!/usr/bin/env bash
# Tmux Workshop Configuration
# This file is loaded by tmux scripts

# Base directory for clusters (not used in workshop but required by scripts)
export CLUSTERS_BASE_PATH="${CLUSTERS_BASE_PATH:-/home/default}"

# Cache directory
export OCP_CACHE_DIR="${OCP_CACHE_DIR:-/home/default/.cache}"

# FZF border label
export FZF_BORDER_LABEL="${FZF_BORDER_LABEL:-tmux workshop}"

# OpenShift credentials (set these when connecting to a cluster)
export OCP_USERNAME="${OCP_USERNAME:-}"
export OCP_PASSWORD="${OCP_PASSWORD:-}"

# Browser (not used in container)
export BROWSER="${BROWSER:-echo}"
