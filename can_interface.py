import os
import time
import can
import logging
import subprocess

class PgnDecoder:
    """Handles decoding of J1939 PGN messages based on lookup table."""

    PGN_TABLE = {
        61444: {"name": "Engine RPM", "startIndex": 3, "byteCount": 2, "scaleFactor": 8.0, "isSigned": False, "offset": 0.0},
        65253: {"name": "Engine Hours", "startIndex": 0, "byteCount": 2, "scaleFactor": 20.0, "isSigned": False, "offset": 0.0},
        65262: {"name": "Coolant Temperature", "startIndex": 0, "byteCount": 1, "scaleFactor": 1.0, "isSigned": False, "offset": -40.0},
        65271: {"name": "Alternator Voltage", "startIndex": 6, "byteCount": 2, "scaleFactor": 20.0, "isSigned": False, "offset": 0.0},
    }

    @staticmethod
    def extract_pgn_value(data, pgn_def):
        """Extracts a value from CAN data using PGN metadata."""
        raw_value = int.from_bytes(data[pgn_def["startIndex"]:pgn_def["startIndex"] + pgn_def["byteCount"]],
                                   byteorder='little', signed=pgn_def["isSigned"])
        return (raw_value / pgn_def["scaleFactor"]) + pgn_def["offset"]

    @classmethod
    def decode(cls, message):
        """Decodes a PGN if found in the lookup table."""
        pgn = (message.arbitration_id >> 8) & 0xFFFF if message.is_extended_id else (message.arbitration_id & 0x7FF)
        if pgn in cls.PGN_TABLE:
            value = cls.extract_pgn_value(message.data, cls.PGN_TABLE[pgn])
            return cls.PGN_TABLE[pgn]["name"], value
        return None, None


class CanInterface:
    """Manages CAN bus initialization and message listening."""

    def __init__(self, bitrate=500000):
        self.bitrate = bitrate
        self.bus = None

    def setup_can(self):
        """Ensures CAN0 is up before starting the bus."""
        if not self.wait_for_can_interface():
            raise RuntimeError("CAN interface did not come up.")
        try:
            logging.info("Opening CAN interface...")
            self.bus = can.interface.Bus(channel="can0", bustype="socketcan")
            logging.info("CAN interface initialized successfully.")
        except Exception as e:
            logging.error(f"Error initializing CAN bus: {e}")
            raise RuntimeError("Error setting up CAN bus.")

    @staticmethod
    def wait_for_can_interface(interface="can0", timeout=10):
        """Waits for the CAN interface to be ready before proceeding."""
        start_time = time.time()
        while time.time() - start_time < timeout:
            if os.system(f"ip link show {interface} > /dev/null 2>&1") == 0:
                logging.info(f"CAN interface {interface} is ready.")
                return True
            logging.warning(f"Waiting for {interface} to be ready...")
            time.sleep(1)
        logging.error(f"CAN interface {interface} did not come up.")
        return False

    def listen(self, processor):
        """Listens for CAN messages and passes them to a processor."""
        logging.info("Listening for CAN messages...")
        try:
            while True:
                msg = self.bus.recv(timeout=1)  # Wait for a message (timeout=1 sec)
                if msg:
                    processor.process_message(msg)

                # Ensure heartbeat runs even if no messages are received
                processor.check_heartbeat()
        except KeyboardInterrupt:
            logging.info("CAN listener stopped by user.")
        finally:
            self.cleanup()

    def cleanup(self):
        """Shuts down the CAN interface properly."""
        logging.info("Shutting down CAN interface...")
        subprocess.run(["sudo", "ip", "link", "set", "can0", "down"], check=False)
