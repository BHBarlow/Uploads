#!/bin/sh

# Install build dependencies
apk add --no-cache \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    make \
    cmake \
    jpeg-dev \
    zlib-dev \
    postgresql-dev \
    cairo-dev \
    pango-dev \
    gdk-pixbuf-dev \
    git

# Upgrade pip and install Wagtail
pip3 install --upgrade pip
pip3 install wagtail psycopg2-binary

# Ensure /app/blog exists before setup
if [ ! -d "/app/blog" ]; then
    mkdir -p /app/tmp
    wagtail start --template=https://github.com/wagtail/news-template/archive/refs/heads/main.zip blog /app/tmp 
    cp -r /app/tmp/* /app/blog
    rm -rf /app/tmp
fi

cd /app/blog

# Install dependencies
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
fi

# Set up database and cache
python3 manage.py createcachetable
python3 manage.py migrate
python3 manage.py collectstatic --noinput

# Ensure first-time setup only runs once
if [ ! -f "/app/blog/finished" ]; then
    python3 manage.py load_initial_data || echo "Skipping initial data load"
    touch /app/blog/finished
fi

# Start the Wagtail server
exec python3 manage.py runserver 0.0.0.0:8000
