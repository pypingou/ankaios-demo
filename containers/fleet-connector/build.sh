#!/bin/bash

set -ex

sudo podman build -t localhost/fleet-connector:latest .
