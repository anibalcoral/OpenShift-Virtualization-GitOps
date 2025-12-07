#!/bin/bash
# OSC 52 clipboard helper for tmux in web terminals
# This sends the clipboard content using OSC 52 escape sequence

if [ "$1" = "-o" ]; then
    # Output mode - for middle-click paste
    # In web terminals, we can't easily read from system clipboard
    # So we just output empty or use tmux's internal buffer
    tmux save-buffer - 2>/dev/null || echo ""
else
    # Input mode - for copy operations
    # Read from stdin and send to clipboard via OSC 52
    input=$(cat)
    
    # OSC 52 sequence: ESC ] 52 ; c ; <base64 data> ESC \
    # Where 'c' means clipboard
    encoded=$(echo -n "$input" | base64 -w0)
    printf "\033]52;c;%s\007" "$encoded"
    
    # Also save to tmux buffer for fallback
    echo -n "$input" | tmux load-buffer -
fi
