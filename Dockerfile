# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
# Install sudo and other essential packages
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    bash \
    build-essential \
    && apt-get clean

# Add non-root user (testuser)
RUN useradd -m testuser && echo "testuser:testuser" | chpasswd && adduser testuser sudo

# Grant passwordless sudo to the testuser
RUN echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to root for copying and permissions
#USER root

# Copy the script and vimrc into the container

# Set the script and vimrc to be executable by the non-root user

# Switch to non-root user
#USER testuser
#WORKDIR /home/testuser

# Run the script
#CMD ["./bootstrap.sh"]

