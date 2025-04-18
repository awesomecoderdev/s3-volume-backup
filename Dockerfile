FROM alpine:latest

# Install needed packages
RUN apk add --no-cache \
    bash \
    zip \
    curl \
    python3 \
    py3-pip \
    cronie \
    aws-cli  # Install AWS CLI via apk to avoid pip issues

# Set work directory
WORKDIR /app

# Copy backup script and cron schedule
COPY uploader.sh /app/uploader.sh
COPY cronjob /etc/crontabs/root

# Copy the local app directory into container
COPY app/mysql /app/mysql
COPY app/backup /app/backup

# Make script executable
RUN chmod +x /app/uploader.sh

# Start cron in foreground (run cron as the container's main process)
CMD crond -f
