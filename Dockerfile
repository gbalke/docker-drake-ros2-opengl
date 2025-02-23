FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04

# Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# Set up user ubuntu with password ubuntu
ARG user=ubuntu
ARG user_pass=ubuntu
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ubuntu
RUN echo "$user:$user_pass" | chpasswd

RUN apt update

# Basic app installation.
RUN DEBIAN_FRONTEND=noninteractive apt install -y -qq --no-install-recommends \
    openssh-server \
    vim \
    git \
    sudo

# Dependencies for glvnd and X11.
RUN DEBIAN_FRONTEND=noninteractive apt install -y -qq --no-install-recommends \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libxext6 \
    libx11-6 \
    mesa-utils \
  && rm -rf /var/lib/apt/lists/*

# Open Ports
# ssh
EXPOSE 1234
# jupyter notebook
EXPOSE 8080

# Set up SSH forwarding.
RUN echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
ADD xorg.conf /usr/share/X11/xorg.conf.d/xorg.conf
RUN service ssh start
CMD ["/usr/sbin/sshd","-D"]

# INSTALLING ROS2
RUN apt update
RUN apt install curl gnupg2 lsb-release -y
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo apt-key add -
RUN echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
    ros-rolling-desktop \
    python3-rosdep2
RUN apt install python3-colcon-common-extensions -y
RUN rosdep update
RUN apt update && apt upgrade -y

# BUILDING AND INSTALLING DRAKE (This must be done as non-sudo)
USER ubuntu
RUN echo "source /opt/ros/rolling/setup.bash" >> /home/ubuntu/.bashrc
