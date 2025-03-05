import time
import logging
import json
import os
from can_interface import PgnDecoder

PIPE_PATH = "/tmp/canbus_pipe"

class CanProcessor:
    """Handles processing and logging of J1939 CAN messages."""

    def __init__(self):
        self.start_time = time.time()
        self.last_message_time = time.time()  # Tracks last received message time
        self.total_received = 0
        self.last_heartbeat = time.time()  # Tracks last heartbeat time
        if not os.path.exists(PIPE_PATH):
            os.mkfifo(PIPE_PATH)        

    def process_message(self, message):
        """Processes an incoming CAN message."""
        self.total_received += 1
        self.last_message_time = time.time()  # Update time when a message is received
        name, value = PgnDecoder.decode(message)

        if name:
            entry = dict(PGNname=name, value=f'{value:.2f}')
        else:
            entry = dict(PGNname='unknown', arbitration_id=f'{message.arbitration_id}')
            logging.warning(f"Unknown PGN: {message.arbitration_id}")

        self.write_to_pipe(entry)

    def check_heartbeat(self):
        """Runs the heartbeat every N seconds even if no messages arrive."""
        if time.time() - self.last_heartbeat >= 5:
            self.heartbeat()
            self.last_heartbeat = time.time()

    def heartbeat(self):
        """Prints system uptime and message statistics every 3 seconds."""
        uptime = int(time.time() - self.start_time)
        quiet_secs = int(time.time() - self.last_message_time)  # Corrected quiet time
        hours, remainder = divmod(uptime, 3600)
        minutes, seconds = divmod(remainder, 60)

        entry = dict(uptime=f'{hours:02}:{minutes:02}:{seconds:02}',
                     messages_received=f'{self.total_received}',
                     quiet_seconds=f'{quiet_secs}')
        self.write_to_pipe(entry)

    def write_to_pipe(self, message):
        """Writes processed messages to the named pipe if a reader exists."""
        try:
            fifo_fd = os.open(PIPE_PATH, os.O_WRONLY | os.O_NONBLOCK)
            with os.fdopen(fifo_fd, "w") as fifo:
                fifo.write(json.dumps(message) + "\n")
                fifo.flush()
        except OSError:
            pass  # No reader is connected; skip writing

