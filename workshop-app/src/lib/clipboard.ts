/**
 * Copy text to clipboard with OSC 52 support for terminal integration
 * This ensures text copied in the browser is also available in the terminal
 */
export async function copyToClipboard(text: string): Promise<void> {
  // Copy to system clipboard using standard API
  await navigator.clipboard.writeText(text)
  
  // Also send to terminal via OSC 52 escape sequence
  // This makes the text available for middle-click paste in tmux
  sendOSC52ToTerminal(text)
}

/**
 * Send text to terminal via OSC 52 escape sequence
 * OSC 52 allows copying text from web terminal to system clipboard
 */
function sendOSC52ToTerminal(text: string): void {
  try {
    // Encode text to base64
    const base64Text = btoa(text)
    
    // Create OSC 52 escape sequence: ESC ] 52 ; c ; <base64> BEL
    // Where 'c' means clipboard
    const osc52 = `\x1b]52;c;${base64Text}\x07`
    
    // Try to send via WebSocket to terminal if available
    // This is a best-effort attempt - if the terminal div is focused,
    // the sequence will be processed by xterm.js
    const event = new CustomEvent('osc52-copy', { 
      detail: { text, osc52 },
      bubbles: true 
    })
    document.dispatchEvent(event)
  } catch (error) {
    // Silently fail - OSC 52 is optional enhancement
    console.debug('OSC 52 send failed:', error)
  }
}
