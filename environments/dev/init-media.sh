#!/bin/bash

# Create media directories with proper ownership
mkdir -p ./media/{movies,shows,books,music,home-videos,music-videos,mixed-movies-shows}
mkdir -p ./config/{jf,jackett,bazarr,qb,radarr,sonarr}

# Set ownership to 1000:1000 (same as Kubernetes deployment)
sudo chown -R 1000:1000 ./media ./config
chmod -R 775 ./media ./config

echo "Media folders initialized with proper ownership (1000:1000)"
echo "Run: docker-compose up -d"
