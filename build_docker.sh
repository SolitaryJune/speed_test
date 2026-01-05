#!/bin/bash
docker build -t speedtest-unlimited .
docker run -it --rm speedtest-unlimited