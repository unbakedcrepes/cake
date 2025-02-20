#!/bin/bash

help() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install <size> <path> <mount_directory>     Install the system with specified size, path, and mount directory."
    echo "  run <command> [args]                        Run a command in a systemd-nspawn container."
    echo "  run <command> --nvidia [args]               Optional flag to include NVIDIA bindings."
    echo ""
    echo "Options:"
    echo "  -h, --help                                  Show this help message."
    echo ""
    echo "Examples:"
    echo "  $0 install 10G /path/to/image.img /mnt"
    echo "  $0 run /bin/bash"
    exit 0
}

install() {
    # Check for the correct number of arguments
    if [ "$#" -ne 3 ]; then
        echo "Error: Invalid number of arguments for install."
        help
        exit 1
    fi

    size=$1
    path=$2
    mnt_dir=$3
    packages="base sudo nano tmux less htop man-pages man-db bash-completion openssh wayland pipewire wireplumber base-devel git"

    # Validate path argument
    if [ -z "$path" ]; then
        echo "Error: Path cannot be empty."
        help
        exit 1
    fi

    # Validate mount directory argument
    if [ -z "$mnt_dir" ]; then
        echo "Error: Mount directory cannot be empty."
        help
        exit 1
    fi

    echo Size: $size
    echo Path: $path
    echo Mount: $mnt_dir

    # Remove existing image file, create a new one, format it, and mount it
    rm $path
    fallocate -l $size $path &&
    mkfs.ext4 $path &&
    mount $path $mnt_dir &&
    pacstrap -c $mnt_dir $packages &&

    # Create a script to run after installation
    echo "#!/bin/bash
    useradd -m -G wheel localuser
    echo 'localuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/pinky
    cd /
    git clone https://aur.archlinux.org/aurman.git
    chown localuser:localuser -R aurman
    cd aurman
    runuser -u localuser -- makepkg -rsic --skippgpcheck --noconfirm
    rm /etc/sudoers.d/pinky
    cd /
    rm -r /aurman
    echo 1234 | passwd localuser --stdin
    echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
    rm \$0
    " > $mnt_dir/once.sh &&
    chmod +x $mnt_dir/once.sh &&
    umount $mnt_dir &&
    systemd-nspawn --quiet --register=yes --image=$path /once.sh
    exit $?
}

run() {
    cmd_base="systemd-nspawn --quiet --link-journal=try-guest --register=yes --bind=/dev/dri --bind=/dev/shm"
    binds_nvidia=""

    # Check for the NVIDIA flag
    if [[ "$1" == "--nvidia" ]]; then
        binds_nvidia="--bind=/dev/nvidia0 --bind=/dev/nvidiactl --bind=/dev/nvidia-modeset --bind=/usr/bin/nvidia-bug-report.sh --bind=/usr/bin/nvidia-cuda-mps-control --bind=/usr/bin/nvidia-cuda-mps-server --bind=/usr/bin/nvidia-debugdump --bind=/usr/bin/nvidia-modprobe --bind=/usr/bin/nvidia-ngx-updater --bind=/usr/bin/nvidia-persistenced --bind=/usr/bin/nvidia-powerd --bind=/usr/bin/nvidia-sleep.sh --bind=/usr/bin/nvidia-smi --bind=/usr/bin/nvidia-xconfig --bind=/usr/lib/gbm/nvidia-drm_gbm.so:/usr/lib/x86_64-linux-gnu/gbm/nvidia-drm_gbm.so --bind=/usr/lib/libEGL_nvidia.so:/usr/lib/x86_64-linux-gnu/libEGL_nvidia.so --bind=/usr/lib/libGLESv1_CM_nvidia.so:/usr/lib/x86_64-linux-gnu/libGLESv1_CM_nvidia.so --bind=/usr/lib/libGLESv2_nvidia.so:/usr/lib/x86_64-linux-gnu/libGLESv2_nvidia.so --bind=/usr/lib/libGLX_nvidia.so:/usr/lib/x86_64-linux-gnu/libGLX_nvidia.so --bind=/usr/lib/libcuda.so:/usr/lib/x86_64-linux-gnu/libcuda.so --bind=/usr/lib/libnvcuvid.so:/usr/lib/x86_64-linux-gnu/libnvcuvid.so --bind=/usr/lib/libnvidia-allocator.so:/usr/lib/x86_64-linux-gnu/libnvidia-allocator.so --bind=/usr/lib/libnvidia-cfg.so:/usr/lib/x86_64-linux-gnu/libnvidia-cfg.so --bind=/usr/lib/libnvidia-egl-gbm.so:/usr/lib/x86_64-linux-gnu/libnvidia-egl-gbm.so --bind=/usr/lib/libnvidia-eglcore.so:/usr/lib/x86_64-linux-gnu/libnvidia-eglcore.so --bind=/usr/lib/libnvidia-encode.so:/usr/lib/x86_64-linux-gnu/libnvidia-encode.so --bind=/usr/lib/libnvidia-fbc.so:/usr/lib/x86_64-linux-gnu/libnvidia-fbc.so --bind=/usr/lib/libnvidia-glcore.so:/usr/lib/x86_64-linux-gnu/libnvidia-glcore.so --bind=/usr/lib/libnvidia-glsi.so:/usr/lib/x86_64-linux-gnu/libnvidia-glsi.so --bind=/usr/lib/libnvidia-glvkspirv.so:/usr/lib/x86_64-linux-gnu/libnvidia-glvkspirv.so --bind=/usr/lib/libnvidia-ml.so:/usr/lib/x86_64-linux-gnu/libnvidia-ml.so --bind=/usr/lib/libnvidia-ngx.so:/usr/lib/x86_64-linux-gnu/libnvidia-ngx.so --bind=/usr/lib/libnvidia-opticalflow.so:/usr/lib/x86_64-linux-gnu/libnvidia-opticalflow.so --bind=/usr/lib/libnvidia-ptxjitcompiler.so:/usr/lib/x86_64-linux-gnu/libnvidia-ptxjitcompiler.so --bind=/usr/lib/libnvidia-rtcore.so:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so --bind=/usr/lib/libnvidia-tls.so:/usr/lib/x86_64-linux-gnu/libnvidia-tls.so --bind=/usr/lib/libnvoptix.so:/usr/lib/x86_64-linux-gnu/libnvoptix.so --bind=/usr/lib/modprobe.d/nvidia-utils.conf:/usr/lib/x86_64-linux-gnu/modprobe.d/nvidia-utils.conf --bind=/usr/lib/nvidia/wine/_nvngx.dll:/usr/lib/x86_64-linux-gnu/nvidia/wine/_nvngx.dll --bind=/usr/lib/nvidia/wine/nvngx.dll:/usr/lib/x86_64-linux-gnu/nvidia/wine/nvngx.dll --bind=/usr/lib/nvidia/xorg/libglxserver_nvidia.so:/usr/lib/x86_64-linux-gnu/nvidia/xorg/libglxserver_nvidia.so --bind=/usr/lib/vdpau/libvdpau_nvidia.so:/usr/lib/x86_64-linux-gnu/vdpau/libvdpau_nvidia.so --bind=/usr/lib/xorg/modules/drivers/nvidia_drv.so:/usr/lib/x86_64-linux-gnu/xorg/modules/drivers/nvidia_drv.so --bind=/usr/share/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf --bind=/usr/share/dbus-1/system.d/nvidia-dbus.conf --bind=/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json --bind=/usr/share/glvnd/egl_vendor.d/10_nvidia.json --bind=/usr/share/licenses/nvidia-utils/LICENSE --bind=/usr/share/vulkan/icd.d/nvidia_icd.json --bind=/usr/share/vulkan/implicit_layer.d/nvidia_layers.json"
        shift
    fi

    #echo $cmd_base $binds_base $binds_nvidia
    cmd="$cmd_base $binds_nvidia --bind=$XDG_RUNTIME_DIR:/run/user/1000"
    $cmd $@
    exit $?
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
elif [ "$1" == "run" ]; then
    shift
    run $@
elif [ "$1" == "install" ]; then
    shift
    install $@
else
    echo "Invalid argument. Please use 'run' or 'install'."
    help
fi
