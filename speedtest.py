#!/usr/bin/env python3
"""
网络速度测试脚本
"""

import time
import random
import argparse
import sys


def speed_test(duration=10, limit=100.00):
    """
    模拟网络速度测试
    :param duration: 测试持续时间（秒）
    :param limit: 限速值（Mbps）
    """
    print(f"开始网络速度测试，限速: {limit} Mbps")
    print(f"测试持续时间: {duration} 秒")
    
    total_data = 0
    start_time = time.time()
    
    for i in range(duration):
        # 模拟数据传输
        data_chunk = random.uniform(0, min(15, limit/8))  # 转换为MB/s并限制每次传输
        total_data += data_chunk
        elapsed = time.time() - start_time
        
        # 计算当前速度
        current_speed = (data_chunk * 8)  # 转换回Mbps
        
        print(f"时间: {elapsed:.2f}s, 速度: {current_speed:.2f} Mbps")
        time.sleep(1)
    
    total_time = time.time() - start_time
    avg_speed = (total_data * 8) / total_time  # 转换为Mbps
    
    print(f"\n测试完成!")
    print(f"总传输数据: {total_data:.2f} MB")
    print(f"平均速度: {avg_speed:.2f} Mbps")
    print(f"最高速度: {limit:.2f} Mbps (限速)")


def main():
    parser = argparse.ArgumentParser(description="网络速度测试工具")
    parser.add_argument("-d", "--duration", type=int, default=10, help="测试持续时间（秒），默认为10")
    parser.add_argument("-l", "--limit", type=float, default=100.00, help="限速值（Mbps），默认为100.00")
    
    args = parser.parse_args()
    
    if args.limit <= 0:
        print("错误: 限速值必须大于0")
        sys.exit(1)
        
    speed_test(args.duration, args.limit)


if __name__ == "__main__":
    main()