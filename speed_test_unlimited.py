#!/usr/bin/env python3
"""
Unlimited Speed Test Script
This script runs continuously without time limits and automatically restarts after completion.
"""

import requests
import time
import threading
import argparse
import sys


class RateLimiter:
    def __init__(self, rate_limit_bytes_per_sec):
        self.rate_limit_bytes_per_sec = rate_limit_bytes_per_sec
        self.last_refill_time = time.time()
        self.current_bytes_available = rate_limit_bytes_per_sec  # Start with a full bucket
        self.lock = threading.Lock()

    def acquire(self, bytes_needed):
        with self.lock:
            now = time.time()
            time_passed = now - self.last_refill_time
            self.last_refill_time = now

            # Refill tokens based on time passed
            self.current_bytes_available = min(self.rate_limit_bytes_per_sec, 
                                               self.current_bytes_available + time_passed * self.rate_limit_bytes_per_sec)

            if self.current_bytes_available >= bytes_needed:
                self.current_bytes_available -= bytes_needed
                return True
            else:
                # Not enough tokens, calculate how long to wait
                bytes_missing = bytes_needed - self.current_bytes_available
                wait_time = bytes_missing / self.rate_limit_bytes_per_sec
                time.sleep(wait_time)
                self.current_bytes_available = 0  # Assume all tokens are used after waiting
                return True  # After waiting, we can proceed


class SpeedTester:
    def __init__(self, url, threads, speed_limit_mbps=None, test_interval=0):
        self.url = url
        self.threads = threads
        self.total_downloaded = 0
        self.start_time = 0
        self.lock = threading.Lock()
        self.running = True
        self.rate_limiter = None
        self.test_interval = test_interval  # Time to wait between tests (0 = no wait)
        if speed_limit_mbps:
            limit_bytes_per_sec = speed_limit_mbps * 1024 * 1024 / 8
            self.rate_limiter = RateLimiter(limit_bytes_per_sec)

    def _download_worker(self):
        chunk_size = 8192
        retries = 3
        backoff_factor = 0.5

        while self.running:
            try:
                response = requests.get(self.url, stream=True, timeout=30)
                response.raise_for_status()
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if not self.running:
                        break
                    if chunk:
                        downloaded_this_chunk = len(chunk)
                        
                        if self.rate_limiter:
                            self.rate_limiter.acquire(downloaded_this_chunk)

                        with self.lock:
                            self.total_downloaded += downloaded_this_chunk
                retries = 3  # Reset retries on successful download

            except requests.exceptions.RequestException as e:
                if retries > 0:
                    print(f"Warning: Download error: {e}. Retrying in {backoff_factor * (2**(3-retries))} seconds...")
                    time.sleep(backoff_factor * (2**(3-retries)))  # Exponential backoff
                    retries -= 1
                else:
                    print(f"Error: Max retries reached for {self.url}. Continuing...")
                    break  # Continue with the next iteration instead of stopping

    def start_test(self):
        while self.running:
            print(f"Starting speed test for {self.url} with {self.threads} threads...")
            if self.rate_limiter:
                print(f"Speed limit set to {self.rate_limiter.rate_limit_bytes_per_sec * 8 / (1024 * 1024):.2f} Mbps")
            
            self.start_time = time.time()
            self.total_downloaded = 0
            thread_list = []
            
            for _ in range(self.threads):
                thread = threading.Thread(target=self._download_worker)
                thread_list.append(thread)
                thread.start()

            try:
                # Keep the main thread alive to allow for graceful shutdown
                while self.running:
                    time.sleep(1)  # Check every second if we should stop
            except KeyboardInterrupt:
                print("\nStopping speed test...")
                self.running = False
            
            # Wait for all threads to finish
            for thread in thread_list:
                thread.join(timeout=5)  # Wait up to 5 seconds for threads to finish

            if self.running:  # Only continue if we're still running (not stopped by user)
                end_time = time.time()
                elapsed_time = end_time - self.start_time

                if elapsed_time > 0:
                    speed_bps = (self.total_downloaded * 8) / elapsed_time
                    speed_mbps = speed_bps / (1024 * 1024)
                    print(f"\nTest completed.")
                    print(f"Total downloaded: {self.total_downloaded / (1024 * 1024):.2f} MB")
                    print(f"Elapsed time: {elapsed_time:.2f} seconds")
                    print(f"Average speed: {speed_mbps:.2f} Mbps")
                else:
                    print("No data downloaded or test duration too short.")
                
                # Wait before starting the next test if interval is specified
                if self.test_interval > 0:
                    print(f"Waiting {self.test_interval} seconds before next test...")
                    time.sleep(self.test_interval)
                
                print("\nStarting next speed test cycle...\n")


def signal_handler(sig, frame):
    print('\nReceived interrupt signal. Exiting...')
    sys.exit(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Unlimited multi-threaded speed test tool that runs continuously.")
    parser.add_argument("--url", type=str, default="https://p1.dailygn.com/obj/g-marketing-act-assets/2024_11_28_14_54_37/mv_1128_1080px.mp4", help="URL to download from for speed test.")
    parser.add_argument("--threads", type=int, default=4, help="Number of concurrent download threads (default: 4).")
    parser.add_argument("--speed-limit", type=float, default=None, help="Speed limit in Mbps (e.g., 8 for 8Mbps). No limit by default.")
    parser.add_argument("--interval", type=int, default=0, help="Time to wait between test cycles in seconds (default: 0, no wait).")

    args = parser.parse_args()

    tester = SpeedTester(args.url, args.threads, args.speed_limit, args.interval)
    tester.start_test()