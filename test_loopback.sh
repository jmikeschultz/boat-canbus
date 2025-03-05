#!/bin/bash

# Set CAN Bus Bitrate (Modify as needed)
CAN_BITRATE=${CAN_BITRATE:-500000}  # Default 500kbps

echo "Starting MCP2515 CAN Bus Loopback Test with bitrate ${CAN_BITRATE}..."
echo

# Step 1: Bring down the CAN interface to reset it
echo "Disabling CAN interface..."
sudo ip link set can0 down

# Step 2: Enable CAN interface with loopback mode
echo "Enabling Loopback Mode on MCP2515 (Bitrate: ${CAN_BITRATE})..."
sudo ip link set can0 up type can bitrate ${CAN_BITRATE} loopback on
sleep 1  # Ensure interface is up

# Step 3: Start candump in the background before sending the message
echo "Starting candump to listen for messages..."
candump can0 > loopback_test.log 2>&1 &
CANDUMP_PID=$!  # Store process ID of candump

# Step 4: Send a test CAN message
echo "Sending test CAN frame: ID=0x123, Data=DEADBEEF"
cansend can0 123#DEADBEEF

# Step 5: Give time for message to appear in candump
sleep 2

# Step 6: Stop candump
echo "Stopping candump..."
sudo kill $CANDUMP_PID

# Step 7: Display captured messages
echo "Loopback test results:"
cat loopback_test.log

# Step 8: Restore normal CAN mode
echo "Restoring CAN interface to normal mode..."
sudo ip link set can0 down
sudo ip link set can0 up type can bitrate ${CAN_BITRATE}

echo "Loopback test completed. CAN bus is back in normal mode."
