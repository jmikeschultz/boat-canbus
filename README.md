canbus_setup.sh sets up the canbus hardware
canbus_listener_setup.sh sets up the canbus listener

/home/mike/boat-canbus/
├── canbus_setup.sh
├── canbus.service
├── canbus_listener.service
└── canbus_listener.py

mike@winch:~/boat-canbus $ ip link show can0
3: can0: <NOARP,UP,LOWER_UP,ECHO> mtu 16 qdisc pfifo_fast state UP mode DEFAULT group default qlen 10
    link/can

mike@winch:~/boat-canbus $ candump can0
  can0  18F00401   [8]  FF FF FF E0 2E FF FF FF
  can0  18FEE501   [8]  6C 25 FF FF FF FF FF FF
  can0  18FEEE01   [8]  AA FF FF FF FF FF FF FF
  can0  18FEF701   [8]  FF FF FF FF FF FF 1B 01
  can0  18F00401   [8]  FF FF FF E0 2E FF FF FF

