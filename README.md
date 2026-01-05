# Unlimited Speed Test Docker

This is a simple Docker setup for an unlimited speed test that runs continuously without time limits and automatically restarts after completion.

## Files

- `speed_test_unlimited.py`: The unlimited speed test script that runs continuously
- `Dockerfile`: Simple Dockerfile to build the image
- `build_docker.sh`: Script to build and run the Docker container

## Usage

To build and run the unlimited speed test:

```bash
chmod +x build_docker.sh
./build_docker.sh
```

Or manually:

```bash
docker build -t speedtest-unlimited .
docker run -it --rm speedtest-unlimited
```

The speed test will run continuously, testing download and upload speeds, then automatically restart after each test.
