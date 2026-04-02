#!/bin/bash

set -ex

podman pull docker.io/eclipse-mosquitto:2

podman run --rm -ti \
    --name mqtt-broker \
    -p 1883:1883 \
    -p 9001:9001 \
    docker.io/eclipse-mosquitto:2
