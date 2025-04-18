# Define variables
IMAGE_NAME = awesomecoder/s3-volume-backup:latest
PLATFORM = linux/amd64

# Build the Docker image
build:
	docker build --platform $(PLATFORM) . -t $(IMAGE_NAME)

# Push the Docker image to the repository
push:
	docker build --platform $(PLATFORM) . -t $(IMAGE_NAME) && docker push $(IMAGE_NAME)
