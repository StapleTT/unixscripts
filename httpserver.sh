#!/bin/bash

echo "Starting HTTP server at $(hostname -I)..."
python -m http.server
