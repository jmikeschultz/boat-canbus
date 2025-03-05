import os
import time
import can
import logging
from can_interface import CanInterface
from can_processor import CanProcessor

# Configure Logging
LOG_FILE = "/var/log/canbus_listener.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

if __name__ == "__main__":
    can_interface = CanInterface()
    processor = CanProcessor()

    try:
        can_interface.setup_can()
        can_interface.listen(processor)
    except RuntimeError as e:
        logging.error(f"Critical error: {e}")
    finally:
        can_interface.cleanup()
