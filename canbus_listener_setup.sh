#!/bin/bash

LISTENER_INSTALLED=false
LOG_DIR="/var/log"
LISTENER_LOG="$LOG_DIR/canbus_listener.log"

echo "Starting CAN Bus Listener setup for RS485 CAN HAT on Raspberry Pi..."
echo

# Step 1: Ensure log file exists with correct ownership and permissions
echo "Configuring log file at $LISTENER_LOG..."
if [ ! -f "$LISTENER_LOG" ]; then
    sudo touch "$LISTENER_LOG"
fi
sudo chown mike:adm "$LISTENER_LOG"  # Give mike ownership, group = adm (standard logging group)
sudo chmod 664 "$LISTENER_LOG"       # Allow write access for mike and adm group

# Step 2: Install CAN Listener systemd service
SETUP_DIR=$(dirname "$(realpath "$0")")

if [ -f "$SETUP_DIR/canbus_listener.service" ]; then
    echo "Installing canbus_listener.service..."
    sudo cp "$SETUP_DIR/canbus_listener.service" /etc/systemd/system/canbus_listener.service
    sudo systemctl daemon-reload
    sudo systemctl enable canbus_listener.service
    sudo systemctl restart canbus_listener.service
    LISTENER_INSTALLED=true
else
    echo "Error: canbus_listener.service not found in $SETUP_DIR"
fi

# Step 3: Ensure canbus_listener.py exists in the setup directory
if [ -f "$SETUP_DIR/canbus_listener.py" ]; then
    echo "Ensuring canbus_listener.py is in place..."
    sudo chmod +x /home/mike/boat-canbus/canbus_listener.py
    LISTENER_INSTALLED=true
else
    echo "Error: canbus_listener.py not found in $SETUP_DIR"
fi

# Step 4: Ask for reboot only if system changes were made
if [ "$LISTENER_INSTALLED" = true ]; then
    echo "System changes were made. A reboot is required."
    read -p "Do you want to reboot now? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo "Rebooting now..."
        sudo reboot
    else
        echo "Please manually reboot later to apply changes."
    fi
else
    echo "No changes were necessary. No reboot required."
fi

echo "CAN Bus Listener setup completed."
