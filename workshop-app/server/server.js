const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const { spawn } = require('node-pty');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server, path: '/terminal' });

const PORT = process.env.PORT || 8080;
const GUIDES_DIR = process.env.GUIDES_DIR || '/app/guides';

app.use(express.static('dist'));
app.use(express.json());

app.get('/api/guides', (req, res) => {
  try {
    if (!fs.existsSync(GUIDES_DIR)) {
      return res.json([]);
    }
    
    const files = fs.readdirSync(GUIDES_DIR)
      .filter(file => file.endsWith('.md'))
      .sort();
    
    res.json(files);
  } catch (error) {
    console.error('Error reading guides directory:', error);
    res.status(500).json({ error: 'Failed to read guides' });
  }
});

app.get('/api/guides/:filename', (req, res) => {
  try {
    const filename = req.params.filename;
    
    if (!filename.endsWith('.md')) {
      return res.status(400).send('Invalid file type');
    }
    
    const filepath = path.join(GUIDES_DIR, filename);
    
    if (!filepath.startsWith(GUIDES_DIR)) {
      return res.status(400).send('Invalid file path');
    }
    
    if (!fs.existsSync(filepath)) {
      return res.status(404).send('Guide not found');
    }
    
    const content = fs.readFileSync(filepath, 'utf-8');
    res.type('text/markdown').send(content);
  } catch (error) {
    console.error('Error reading guide file:', error);
    res.status(500).send('Failed to read guide');
  }
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

wss.on('connection', (ws) => {
  console.log('New terminal connection');
  
  // Check if tmux should be used (via env var)
  const useTmux = process.env.USE_TMUX === 'true';
  const shell = useTmux ? '/usr/local/bin/tmux' : (process.env.SHELL || '/bin/bash');
  const shellArgs = useTmux ? ['new-session', '-A', '-s', 'workshop', '/bin/bash', '-l'] : [];
  const namespace = process.env.NAMESPACE || '';
  
  // Configure environment to use ServiceAccount token from pod
  const env = { ...process.env };
  
  // Remove KUBECONFIG to force in-cluster token usage
  delete env.KUBECONFIG;
  
  // Set HOME
  if (!env.HOME) {
    env.HOME = '/home/default';
  }
  
  // Ensure HOME directory exists
  const fs = require('fs');
  if (!fs.existsSync(env.HOME)) {
    fs.mkdirSync(env.HOME, { recursive: true, mode: 0o755 });
  }

  const ptyProcess = spawn(shell, shellArgs, {
    name: 'xterm-256color',
    cols: 120,
    rows: 40,
    cwd: env.HOME,
    env: env,
  });

  // Configure initial environment
  const containerName = process.env.HOSTNAME || 'workshop';
  
  if (!useTmux) {
    // Only for bash (not tmux)
    setTimeout(() => {
      // Configure PS1 to show container name
      ptyProcess.write(`export PS1='\\[\\033[01;32m\\]${containerName}\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ '\n`);
      
      // Auto-configure OpenShift project if NAMESPACE is set
      if (namespace) {
        // Clear any corrupted kubeconfig and set project
        ptyProcess.write(`rm -f ~/.kube/config 2>/dev/null; oc project ${namespace} > /dev/null 2>&1\n`);
      }
    }, 500);
  } else {
    // For tmux, just configure the project silently
    setTimeout(() => {
      if (namespace) {
        ptyProcess.write(`oc project ${namespace} > /dev/null 2>&1\n`);
        ptyProcess.write('clear\n');
      }
    }, 1000);
  }

  ptyProcess.onData((data) => {
    try {
      ws.send(data);
    } catch (err) {
      console.error('Error sending data to client:', err);
    }
  });

  ws.on('message', (message) => {
    try {
      // Convert Buffer to string
      let data;
      if (typeof message === 'string') {
        data = message;
      } else if (Buffer.isBuffer(message)) {
        data = message.toString('utf8');
      } else if (message instanceof ArrayBuffer) {
        data = Buffer.from(message).toString('utf8');
      } else {
        console.error('Unexpected message type:', typeof message);
        return;
      }
      
      // Try to parse as JSON for resize commands
      try {
        const parsed = JSON.parse(data);
        if (parsed && parsed.type === 'resize' && parsed.cols && parsed.rows) {
          ptyProcess.resize(parsed.cols, parsed.rows);
          return;
        }
      } catch (e) {
        // Not JSON, continue as normal text
      }
      
      // Write only if valid non-empty string
      if (typeof data === 'string' && data.length > 0) {
        ptyProcess.write(data);
      }
    } catch (err) {
      console.error('Error handling message:', err);
    }
  });

  ws.on('close', () => {
    console.log('Terminal connection closed');
    ptyProcess.kill();
  });

  ptyProcess.onExit(() => {
    try {
      ws.close();
    } catch (err) {
      console.error('Error closing websocket:', err);
    }
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Guides directory: ${GUIDES_DIR}`);
});
