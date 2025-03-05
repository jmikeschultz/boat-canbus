#!/bin/bash

CONFIG_FILE="/boot/firmware/config.txt"
CAN_BITRATE=${CAN_BITRATE:-500000}  # Default CAN bitrate
SPI_CHANGED=false
CAN_INSTALLED=false

echo "Starting CAN Bus setup for RS485 CAN HAT on Raspberry Pi..."
echo

# Step 1: Ensure SPI is enabled (RS485 CAN HAT uses SPI for MCP2515)
if ! grep -q "^dtparam=spi=on" "$CONFIG_FILE"; then
    echo "Enabling SPI in $CONFIG_FILE..."
    echo "dtparam=spi=on" | sudo tee -a "$CONFIG_FILE"
    SPI_CHANGED=true
else
    echo "SPI is already enabled."
fi

OVERLAY="dtoverlay=mcp2515-can0,oscillator=12000000,interrupt=25,spimaxfrequency=2000000"
# Step 2: Configure the correct MCP2515 overlay with the proper parameters
if ! grep -q "^${OVERLAY}" "$CONFIG_FILE"; then
    echo "Configuring RS485 CAN HAT overlay..."
    sudo sed -i '/dtoverlay=mcp2515/d' "$CONFIG_FILE"  # Remove any old overlay
    echo "${OVERLAY}" | sudo tee -a "$CONFIG_FILE"
    SPI_CHANGED=true
else
    echo "RS485 CAN HAT overlay is already configured correctly."
fi

# Step 3: Disable RS485 (if enabled) since it's not being used
if grep -q "^dtoverlay=rs485" "$CONFIG_FILE"; then
    echo "Disabling RS485 overlay..."
    sudo sed -i '/dtoverlay=rs485/d' "$CONFIG_FILE"
    SPI_CHANGED=true
else
    echo "RS485 is already disabled."
fi

# Step 4: Install necessary packages only if missing
echo "Checking required packages..."
if ! dpkg -l | grep -qw can-utils; then
    echo "Installing can-utils..."
    sudo apt update && sudo apt install -y can-utils
    CAN_INSTALLED=true
else
    echo "can-utils is already installed."
fi

if ! dpkg -l | grep -qw python3-can; then
    echo "Installing python3-can..."
    sudo apt install -y python3-can
    CAN_INSTALLED=true
else
    echo "python3-can is already installed."
fi

if ! dpkg -l | grep -qw python3-rpi.gpio; then
    echo "Installing python3-rpi.gpio..."
    sudo apt install -y python3-rpi.gpio
    CAN_INSTALLED=true
else
    echo "python3-rpi.gpio is already installed."
fi

# Step 5: Install CAN Bus systemd service
SETUP_DIR=$(dirname "$(realpath "$0")")

if [ -f "$SETUP_DIR/canbus.service" ]; then
    echo "Installing canbus.service..."
    sudo cp "$SETUP_DIR/canbus.service" /etc/systemd/system/canbus.service
    sudo systemctl daemon-reload
    sudo systemctl enable canbus.service
    sudo systemctl restart canbus.service
else
    echo "Error: canbus.service not found in $SETUP_DIR"
fi

# Step 6: Ask for reboot only if system changes were made
if [ "$SPI_CHANGED" = true ] || [ "$CAN_INSTALLED" = true ]; then
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

echo "RS485 CAN HAT setup completed."
