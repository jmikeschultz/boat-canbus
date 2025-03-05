# CAN Bus Setup and Listener

## Overview
This repository contains scripts for setting up and monitoring a **CAN bus interface** on a Raspberry Pi using the **SocketCAN** framework.

## Scripts

- **`canbus_setup.sh`** – Sets up the CAN bus hardware.
- **`canbus_listener_setup.sh`** – Installs and configures the CAN bus listener service.

## File Structure

```
/home/mike/boat-canbus/
├── canbus_setup.sh             # Script to configure CAN hardware
├── canbus.service              # Systemd service for CAN setup
├── canbus_listener.service     # Systemd service for the CAN listener
└── canbus_listener.py          # Python script to read CAN messages
```

## Verifying CAN Bus

### **Check if `can0` is Up**
Run the following command to verify the interface status:

```sh
ip link show can0
```

#### **Expected Output (if `can0` is running)**
```
3: can0: <NOARP,UP,LOWER_UP,ECHO> mtu 16 qdisc pfifo_fast state UP mode DEFAULT group default qlen 10
    link/can
```

---

### **Monitoring CAN Messages**
Use `candump` to monitor incoming CAN messages:

```sh
candump can0
```

#### **Example Output**
```
can0  18F00401   [8]  FF FF FF E0 2E FF FF FF
can0  18FEE501   [8]  6C 25 FF FF FF FF FF FF
can0  18FEEE01   [8]  AA FF FF FF FF FF FF FF
can0  18FEF701   [8]  FF FF FF FF FF FF 1B 01
can0  18F00401   [8]  FF FF FF E0 2E FF FF FF
```

---

### **Restarting the CAN Bus Listener**
If the listener is not running, restart the systemd service:

```sh
sudo systemctl restart canbus_listener.service
```
To check if it’s running:

```sh
systemctl status canbus_listener.service
```

To view logs in real-time:

```sh
tail -f /var/log/canbus_listener.log
```

---

### **Troubleshooting**
#### **1. If `can0` is not available:**
```sh
ip link set can0 up type can bitrate 500000
```

#### **2. If no messages appear in `candump`:**
- Check wiring and CAN connections.
- Ensure the device is transmitting messages.
- Try restarting the interface:
  ```sh
  sudo ip link set can0 down
  sudo ip link set can0 up
  ```

