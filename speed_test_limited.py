import requests
import time
import threading
import argparse
import random
import signal
import sys

class RateLimiter:
    def __init__(self, rate_limit_bytes_per_sec):
        self.rate_limit_bytes_per_sec = rate_limit_bytes_per_sec
        self.last_refill_time = time.time()
        self.current_bytes_available = rate_limit_bytes_per_sec # Start with a full bucket
        self.lock = threading.Lock()

    def acquire(self, bytes_needed):
        with self.lock:
            now = time.time()
            time_passed = now - self.last_refill_time
            self.last_refill_time = now

            # Refill tokens based on time passed
            self.current_bytes_available = min(self.rate_limit_bytes_per_sec, \
                                               self.current_bytes_available + time_passed * self.rate_limit_bytes_per_sec)

            if self.current_bytes_available >= bytes_needed:
                self.current_bytes_available -= bytes_needed
                return True
            else:
                # Not enough tokens, calculate how long to wait
                bytes_missing = bytes_needed - self.current_bytes_available
                wait_time = bytes_missing / self.rate_limit_bytes_per_sec
                time.sleep(wait_time)
                self.current_bytes_available = 0 # Assume all tokens are used after waiting
                return True # After waiting, we can proceed

class SpeedTester:
    def __init__(self, urls, threads, speed_limit_mbps=None):
        self.urls = urls
        self.threads = threads
        self.total_downloaded = 0
        self.start_time = time.time()
        self.lock = threading.Lock()
        self.running = True
        self.rate_limiter = None
        if speed_limit_mbps:
            limit_bytes_per_sec = speed_limit_mbps * 1024 * 1024 / 8
            self.rate_limiter = RateLimiter(limit_bytes_per_sec)

    def _download_worker(self):
        chunk_size = 8192
        # 每个线程下载多少字节后强制换网址 (例如 5MB)
        switch_threshold = 5 * 1024 * 1024 

        while self.running:
            url = random.choice(self.urls)
            downloaded_from_this_url = 0
            try:
                # 增加 stream=True 以便分块处理和随时切换
                response = requests.get(url, stream=True, timeout=15)
                response.raise_for_status()
                
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if not self.running:
                        break
                    
                    if chunk:
                        chunk_len = len(chunk)
                        if self.rate_limiter:
                            self.rate_limiter.acquire(chunk_len)

                        with self.lock:
                            self.total_downloaded += chunk_len
                        
                        downloaded_from_this_url += chunk_len
                        
                        # 达到阈值，跳出循环换下一个网址
                        if downloaded_from_this_url >= switch_threshold:
                            break
                
            except Exception:
                # 忽略单个链接的错误，直接换下一个
                if not self.running:
                    break
                time.sleep(0.1)

    def start_test(self):
        print(f"Starting continuous speed test with {self.threads} threads...")
        print(f"URLs will be automatically switched every 5MB of download per thread.")
        if self.rate_limiter:
            print(f"Speed limit set to {self.rate_limiter.rate_limit_bytes_per_sec * 8 / (1024 * 1024):.2f} Mbps")
        
        thread_list = []
        for _ in range(self.threads):
            thread = threading.Thread(target=self._download_worker)
            thread_list.append(thread)
            thread.start()

        last_total_downloaded = 0
        last_time = time.time()
        try:
            while self.running:
                time.sleep(1)
                current_time = time.time()
                with self.lock:
                    current_downloaded = self.total_downloaded
                
                time_diff = current_time - last_time
                download_diff = current_downloaded - last_total_downloaded

                if time_diff > 0:
                    current_speed_mbps = (download_diff * 8) / (time_diff * 1024 * 1024)
                    print(f"Current speed: {current_speed_mbps:.2f} Mbps")
                
                last_total_downloaded = current_downloaded
                last_time = current_time

        except KeyboardInterrupt:
            self.running = False

        for thread in thread_list:
            thread.join()

def signal_handler(sig, frame):
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)

    parser = argparse.ArgumentParser(description="Continuous speed test with automatic URL switching.")
    parser.add_argument("--urls", type=str, nargs="*", 
                        default=[
                            "https://p1.dailygn.com/obj/g-marketing-act-assets/2024_11_28_14_54_37/mv_1128_1080px.mp4",
                            "https://ossweb-img.qq.com/images/lol/web201310/skin/big10001.jpg",
                            "https://ossweb-img.qq.com/upload/webplat/info/cf/20230717/653421385804853.png",
                            "https://puui.qpic.cn/vpic_cover/g3346tki83w/g3346tki83w_hz.jpg",
                            "https://wegame.gtimg.com/g.55555-r.c4663/wegame-home/sc02-03.514d7db8.png",
                            "https://staticsns.cdn.bcebos.com/amis/2024-12/1733110167508/ec2943f8f5e27bd38f00c6e02.png",
                            "https://issuepcdn.baidupcs.com/issue/netdisk/yunguanjia/BaiduNetdisk_7.54.0.103.exe",
                            "https://nd-static.bdstatic.com/m-static/wp-brand/img/banner.5783471b.png",
                            "https://static-d.iqiyi.com/ext/common/iQIYIMedia_000.dmg",
                            "https://vd3.bdstatic.com/mda-pm9zn07ydwzhfw85/1080p/cae_h264/1702252000350219836/mda-pm9zn07ydwzhfw85.mp4",
                            "https://m1.ad.10010.com/small_video/uploadImg/1598021193891.jpg"
                        ],
                        help="URLs to download from.")
    parser.add_argument("--threads", type=int, default=4, help="Number of threads.")
    parser.add_argument("--speed-limit", type=float, default=100.0, help="Speed limit in Mbps.")

    args = parser.parse_args()

    tester = SpeedTester(args.urls, args.threads, args.speed_limit)
    tester.start_test()
