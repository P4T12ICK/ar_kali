#!/bin/bash
# VNC Server Manager Script
# Ensures VNC server is running and restarts it if needed

# Don't use strict mode to allow better error handling
set -u

# Get the user running this script
VNC_USER="${1:-$(whoami)}"
VNC_DISPLAY="${2:-1}"
VNC_RESOLUTION="${3:-1920x1080}"

# Get user's home directory
VNC_HOME=$(getent passwd "$VNC_USER" | cut -d: -f6)

if [ -z "$VNC_HOME" ]; then
    echo "Error: User $VNC_USER not found" >&2
    exit 1
fi

# Function to check if VNC server is running
check_vnc_running() {
    # Check if process is running
    if pgrep -f "Xtigervnc.*:$VNC_DISPLAY" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to start VNC server
start_vnc() {
    echo "Starting VNC server on display :$VNC_DISPLAY for user $VNC_USER..."
    
    # Kill any stale VNC server first
    if [ -f "$VNC_HOME/.config/tigervnc/$(hostname):$VNC_DISPLAY.pid" ]; then
        echo "Found stale PID file, cleaning up..."
        su - "$VNC_USER" -c "export HOME='$VNC_HOME' && vncserver -kill :$VNC_DISPLAY" 2>&1 || true
        sleep 2
    fi
    
    # Also check for running processes and kill them
    if pgrep -f "Xtigervnc.*:$VNC_DISPLAY" > /dev/null 2>&1; then
        echo "Found running VNC process, stopping it..."
        su - "$VNC_USER" -c "export HOME='$VNC_HOME' && vncserver -kill :$VNC_DISPLAY" 2>&1 || true
        sleep 2
    fi
    
    # Ensure directories exist
    mkdir -p "$VNC_HOME/.vnc"
    mkdir -p "$VNC_HOME/.config/tigervnc"
    chown -R "$VNC_USER:$VNC_USER" "$VNC_HOME/.vnc" "$VNC_HOME/.config/tigervnc" 2>/dev/null || true
    
    # Check if password file exists
    if [ ! -f "$VNC_HOME/.vnc/passwd" ] && [ ! -f "$VNC_HOME/.config/tigervnc/passwd" ]; then
        echo "Warning: VNC password file not found. VNC server may fail to start." >&2
        echo "Password files checked:" >&2
        echo "  - $VNC_HOME/.vnc/passwd" >&2
        echo "  - $VNC_HOME/.config/tigervnc/passwd" >&2
    fi
    
    # Start VNC server with -localhost no to allow external connections
    echo "Executing vncserver command..."
    VNC_OUTPUT=$(su - "$VNC_USER" -c "export HOME='$VNC_HOME' && export DISPLAY=':$VNC_DISPLAY' && cd '$VNC_HOME' && vncserver :$VNC_DISPLAY -geometry $VNC_RESOLUTION -depth 24 -localhost no 2>&1")
    VNC_EXIT_CODE=$?
    
    echo "$VNC_OUTPUT"
    
    if [ $VNC_EXIT_CODE -ne 0 ]; then
        # Check if it's just "already in use" error, which is OK
        if echo "$VNC_OUTPUT" | grep -q "already in use\|New Xtigervnc server"; then
            echo "VNC server appears to be running (or was started)"
        else
            echo "Error: vncserver command failed with exit code $VNC_EXIT_CODE" >&2
            return 1
        fi
    fi
    
    # Wait a moment and verify it started
    sleep 3
    if check_vnc_running; then
        echo "VNC server started successfully on display :$VNC_DISPLAY"
        # Verify it's listening on the port
        VNC_PORT=$((5900 + VNC_DISPLAY))
        if netstat -tln 2>/dev/null | grep -q ":$VNC_PORT " || ss -tln 2>/dev/null | grep -q ":$VNC_PORT "; then
            echo "VNC server is listening on port $VNC_PORT"
        fi
        return 0
    else
        echo "Error: VNC server process not found after startup attempt" >&2
        echo "Last vncserver output:" >&2
        echo "$VNC_OUTPUT" >&2
        return 1
    fi
}

# Main logic
if check_vnc_running; then
    echo "VNC server is already running on display :$VNC_DISPLAY"
    exit 0
else
    start_vnc
    exit $?
fi
