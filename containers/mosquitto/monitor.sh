#!/bin/bash

podman run --rm -ti --network host --name mqtt-broker2  docker.io/eclipse-mosquitto:2 \
  mosquitto_sub -h localhost -t "#"
