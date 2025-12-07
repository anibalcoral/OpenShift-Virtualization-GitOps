import { useEffect, useRef, useState } from 'react'
import { Terminal as XTerm } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import '@xterm/xterm/css/xterm.css'
import { Button } from './ui/button'
import { Badge } from './ui/badge'
import { Trash, ArrowClockwise, Terminal as TerminalIcon } from '@phosphor-icons/react'
import { cn } from '@/lib/utils'

interface TerminalProps {
  className?: string
}

type ConnectionStatus = 'connected' | 'connecting' | 'disconnected'

export function Terminal({ className }: TerminalProps) {
  const terminalRef = useRef<HTMLDivElement>(null)
  const xtermRef = useRef<XTerm | null>(null)
  const fitAddonRef = useRef<FitAddon | null>(null)
  const wsRef = useRef<WebSocket | null>(null)
  const [status, setStatus] = useState<ConnectionStatus>('connecting')
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | undefined>(undefined)

  const connect = () => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      return
    }

    setStatus('connecting')
    
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const wsUrl = `${protocol}//${window.location.host}/terminal`
    
    const ws = new WebSocket(wsUrl)
    wsRef.current = ws

    ws.onopen = () => {
      setStatus('connected')
      if (xtermRef.current) {
        xtermRef.current.write('\r\n\x1b[32m✓ Connected to OpenShift cluster\x1b[0m\r\n')
        
        // Send terminal size immediately
        if (fitAddonRef.current) {
          fitAddonRef.current.fit()
        }
        if (ws.readyState === WebSocket.OPEN && xtermRef.current) {
          ws.send(JSON.stringify({
            type: 'resize',
            cols: xtermRef.current.cols,
            rows: xtermRef.current.rows,
          }))
        }
      }
    }

    ws.onmessage = (event) => {
      if (xtermRef.current) {
        xtermRef.current.write(event.data)
      }
    }

    ws.onerror = () => {
      setStatus('disconnected')
    }

    ws.onclose = () => {
      setStatus('disconnected')
      if (xtermRef.current) {
        xtermRef.current.write('\r\n\x1b[31m✗ Connection lost to cluster\x1b[0m\r\n')
      }
      
      reconnectTimeoutRef.current = setTimeout(() => {
        connect()
      }, 2000)
    }
  }

  useEffect(() => {
    if (!terminalRef.current) return

    const term = new XTerm({
      cursorBlink: true,
      fontSize: 13,
      fontFamily: "'Red Hat Mono', 'JetBrains Mono', Consolas, monospace",
      lineHeight: 1.4,
      rightClickSelectsWord: false,
      theme: {
        background: '#191919',
        foreground: '#f0f0f0',
        cursor: '#ee0000',
        cursorAccent: '#ffffff',
        selectionBackground: '#424242',
        black: '#000000',
        red: '#ee0000',
        green: '#41af46',
        yellow: '#e18114',
        blue: '#217ee7',
        magenta: '#a0439c',
        cyan: '#00c5c7',
        white: '#c7c7c7',
        brightBlack: '#5d5d5d',
        brightRed: '#ff6d67',
        brightGreen: '#5ff967',
        brightYellow: '#fefb67',
        brightBlue: '#6871ff',
        brightMagenta: '#ff76ff',
        brightCyan: '#5ffdff',
        brightWhite: '#ffffff',
      },
    })

    const fitAddon = new FitAddon()
    term.loadAddon(fitAddon)
    term.open(terminalRef.current)
    
    // Small delay to ensure DOM is ready
    setTimeout(() => {
      fitAddon.fit()
      // Send initial size to server
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        wsRef.current.send(JSON.stringify({
          type: 'resize',
          cols: term.cols,
          rows: term.rows,
        }))
      }
    }, 100)

    xtermRef.current = term
    fitAddonRef.current = fitAddon

    term.onData((data) => {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        wsRef.current.send(data)
      }
    })

    // Prevent default paste behavior and handle manually to avoid duplication
    const handlePaste = (event: ClipboardEvent) => {
      event.preventDefault()
      const text = event.clipboardData?.getData('text')
      if (text && wsRef.current?.readyState === WebSocket.OPEN) {
        wsRef.current.send(text)
      }
    }

    // Prevent Ctrl+W from closing browser tab and let bash handle it
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.ctrlKey && event.key === 'w') {
        event.preventDefault()
      }
    }

    terminalRef.current.addEventListener('paste', handlePaste)
    terminalRef.current.addEventListener('keydown', handleKeyDown)

    // Connect immediately without delay
    connect()

    const handleResize = () => {
      fitAddon.fit()
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        wsRef.current.send(JSON.stringify({
          type: 'resize',
          cols: term.cols,
          rows: term.rows,
        }))
      }
    }

    // Observe terminal container size changes
    const resizeObserver = new ResizeObserver(() => {
      handleResize()
    })
    
    if (terminalRef.current) {
      resizeObserver.observe(terminalRef.current)
    }

    window.addEventListener('resize', handleResize)

    return () => {
      if (terminalRef.current) {
        terminalRef.current.removeEventListener('paste', handlePaste)
        terminalRef.current.removeEventListener('keydown', handleKeyDown)
      }
      resizeObserver.disconnect()
      window.removeEventListener('resize', handleResize)
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current)
      }
      term.dispose()
      wsRef.current?.close()
    }
  }, [])

  const handleClear = () => {
    xtermRef.current?.clear()
  }

  const handleReconnect = () => {
    if (wsRef.current) {
      wsRef.current.close()
    }
    connect()
  }

  const getStatusBadge = () => {
    switch (status) {
      case 'connected':
        return (
          <Badge variant="outline" className="border-success/30 bg-success/10 text-success text-xs font-medium">
            <div className="w-1.5 h-1.5 rounded-full bg-success mr-1.5" />
            Connected
          </Badge>
        )
      case 'connecting':
        return (
          <Badge variant="outline" className="border-warning/30 bg-warning/10 text-warning text-xs font-medium">
            <div className="w-1.5 h-1.5 rounded-full bg-warning mr-1.5 animate-pulse" />
            Connecting...
          </Badge>
        )
      case 'disconnected':
        return (
          <Badge variant="outline" className="border-destructive/30 bg-destructive/10 text-destructive text-xs font-medium">
            <div className="w-1.5 h-1.5 rounded-full bg-destructive mr-1.5" />
            Disconnected
          </Badge>
        )
    }
  }

  return (
    <div className={className}>
      <div className="h-full flex flex-col overflow-hidden">
        <div className="flex items-center justify-between px-4 py-2 bg-[var(--toolbar-bg)] border-b border-border">
          <div className="flex items-center gap-2">
            <TerminalIcon size={16} weight="bold" className="text-[var(--toolbar-fg)]" />
            <span className="text-sm font-medium text-foreground">OpenShift Terminal</span>
          </div>
          <div className="flex items-center gap-3">
            {getStatusBadge()}
            <div className="flex items-center gap-1">
              {status === 'disconnected' && (
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={handleReconnect}
                  className="h-7 px-2 text-xs hover:bg-accent/10 hover:text-accent"
                  title="Reconnect"
                >
                  <ArrowClockwise size={14} weight="bold" />
                </Button>
              )}
              <Button
                size="sm"
                variant="ghost"
                onClick={handleClear}
                className="h-7 px-2 text-xs hover:bg-accent/10 hover:text-accent"
                title="Clear terminal"
              >
                <Trash size={14} weight="bold" />
              </Button>
            </div>
          </div>
        </div>
        <div ref={terminalRef} className="flex-1 p-2 overflow-hidden bg-[var(--terminal-bg)]" />
      </div>
    </div>
  )
}
