# GitOps Virtualization Workshop Application

Interactive web application for the OpenShift Virtualization GitOps workshop with split-pane UI: Markdown guides (left) + WebSocket terminal (right).

## Architecture

```
Frontend (React + TypeScript)  →  Backend (Node.js + Express)  →  OpenShift Cluster
     ↓ WebSocket (/terminal)          ↓ PTY (node-pty)              ↓
   xterm.js                        shell session              oc/kubectl commands
```

- **Frontend**: Vite + React 19 + Tailwind CSS + shadcn/ui + xterm.js
- **Backend**: Express + WebSocket (ws) + node-pty for terminal emulation
- **Deployment**: Multi-stage Dockerfile, Kubernetes manifests in `deploy/`

## Directory Structure

```
workshop-app/
├── Dockerfile              # Multi-stage build
├── package.json            # Frontend dependencies
├── vite.config.ts          # Vite configuration
├── tsconfig.json           # TypeScript configuration
├── tailwind.config.js      # Tailwind CSS configuration
├── index.html              # HTML entry point
├── src/                    # Frontend source code
│   ├── App.tsx            # Main application component
│   ├── main.tsx           # React entry point
│   ├── components/        # React components
│   │   ├── Terminal.tsx   # xterm.js terminal
│   │   ├── Navigation.tsx # Sidebar navigation
│   │   ├── MarkdownViewer.tsx # Markdown renderer
│   │   └── ui/           # shadcn/ui components
│   ├── hooks/            # Custom React hooks
│   ├── lib/              # Utilities
│   └── styles/           # CSS styles
├── server/               # Backend server
│   ├── package.json     # Server dependencies
│   └── server.js        # Express + WebSocket server
├── tmux-config/         # Terminal configuration
├── deploy/              # Kubernetes manifests
│   ├── 02-serviceaccount.yaml
│   ├── 03-rolebinding.yaml
│   ├── 04-configmap-guides.yaml
│   ├── 05-deployment.yaml
│   ├── 06-service.yaml
│   └── 07-route.yaml
└── scripts/             # Build and deploy scripts
    ├── build.sh
    ├── deploy.sh
    ├── build-and-deploy.sh
    └── generate-configmap.sh
```

## Quick Start

### Build and Push Image

```bash
# Build the container image
./scripts/build.sh

# Push to registry
podman push quay.io/chiaretto/gitops-virtualization-workshop:latest
```

### Deploy to OpenShift

```bash
# Create namespace (if needed)
oc new-project workshop-gitops

# Deploy the application
./scripts/deploy.sh
```

### Or Build and Deploy in One Step

```bash
./scripts/build-and-deploy.sh
```

## Development

### Local Frontend Development

```bash
# Install dependencies
npm install

# Start development server (hot reload on :5173)
npm run dev
```

### Local Backend Development

```bash
cd server
npm install

# Start backend server
GUIDES_DIR=../demo-guides node server.js
```

## Updating Guides

The workshop guides are loaded from the `demo-guides/` directory in the parent project. To update the ConfigMap with the latest guides:

```bash
./scripts/generate-configmap.sh
```

This will regenerate `deploy/04-configmap-guides.yaml` with all `DEMO*.md` files.

## Image Registry

- **Registry**: quay.io/chiaretto/gitops-virtualization-workshop
- **Build**: `./scripts/build.sh`
- **Push**: `podman push quay.io/chiaretto/gitops-virtualization-workshop:latest`

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `GUIDES_DIR` | `/app/guides` | Directory containing markdown guides |
| `USE_TMUX` | `true` | Enable tmux for terminal sessions |
| `NAMESPACE` | (from pod) | Current OpenShift namespace |

## API Endpoints

- `GET /api/guides` - List available markdown guides
- `GET /api/guides/:filename` - Get guide content
- `WebSocket /terminal` - PTY terminal session

## Features

- Split-pane UI with resizable panels
- Markdown rendering with syntax highlighting
- Copy code blocks to clipboard
- WebSocket-based terminal with xterm.js
- Tmux support for persistent sessions
- Mobile-responsive design
- Dark terminal theme

## Troubleshooting

### Terminal Issues

If the terminal doesn't connect:
1. Check pod logs: `oc logs -l app=gitops-workshop`
2. Verify ServiceAccount permissions
3. Check WebSocket route configuration

### Build Issues

If `node-pty` fails to build:
```bash
cd server && npm rebuild node-pty
```

### Guide Not Loading

1. Verify ConfigMap is mounted: `oc describe pod -l app=gitops-workshop`
2. Check guides directory: `oc exec -it <pod> -- ls /app/guides`
