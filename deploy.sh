#!/bin/bash

set -e
zola build
rsync -rav public/ root@ariedro.dev:/data/ariedro
echo "Deployed!"