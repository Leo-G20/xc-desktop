FROM ubuntu:24.04

# Set apt to non iteractive during build time
ENV DEBIAN_FRONTEND=noniteractive

WORKDIR /xc_install
ARG XC_COMMIT_ID=225b80c5ffe369283d5dec8b22f033416056d820

ARG MAKE_WORKERS=4
ARG RUN_TESTS=0


RUN \
    # Update and upgrade apt
    apt update -y && apt upgrade -y && \
    # Install sudo: Only need to be done on Docker
    apt install -y sudo && \
    # Add universe repository so it can find gtk3-dev packages
    sudo apt install -y software-properties-common && sudo add-apt-repository universe && sudo apt update && \
    # Install Python3 and make is default
    sudo apt install -y python3 python-is-python3 && \
    # Install essential packages
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget && \
    sudo apt install -y git cmake g++ gfortran libboost-all-dev && \
    # Install XC Dependencies
    sudo apt install -y libarpack2-dev libarpack++2-dev libcgal-dev libcgal-qt5-dev libdb-dev libf2c2-dev libglib2.0-dev libgmp3-dev libgtk-3-dev libgtkmm-3.0-dev libgts-bin libgts-dev liblapack-dev libmumps-dev libmpfr-dev libmysql++-dev libplot-dev libsqlite3-dev libsuperlu-dev libsuitesparse-dev libvtk9-dev libvtk9-qt-dev libx11-dev libspectra-dev libmetis-dev && \
    sudo apt install -y python3-dev cimg-dev petsc-dev tcl-dev && \
    sudo apt install -y python3-vtk9 python3-numpy python3-scipy python3-sympy python3-matplotlib python3-pandas python3-sklearn python3-flatlatex python3-pip && \
    sudo apt install -y gnuplot python3-pip bc graphicsmagick-imagemagick-compat && \
    sudo apt install -y mayavi2 python3-ezdxf python3-cairo python3-cairo-dev && \
    sudo apt install -y libgmsh-dev python3-gmsh python3-pygmsh libgmsh4.12 && \
    sudo apt clean

# Fetch a fixed XC revision. Changing it does not invalidate dependency installation.
RUN git clone https://github.com/xcfem/xc/ xc && \
    cd xc && \
    git switch --detach "$XC_COMMIT_ID"

# Configure and build XC.
RUN mkdir /xc_install/build && \
    cd /xc_install/build && \
    cmake /xc_install/xc/src && \
    make -j "$MAKE_WORKERS" && \
    sudo make install

# Install the XC Python modules.
RUN cd /xc_install/xc/python_modules && \
    sudo sh local_install.sh

# The full verification suite is optional and disabled by default.
RUN if [ "$RUN_TESTS" -ne 0 ]; then cd /xc_install/xc/verif && sh run_verif.sh; fi

# Install the desktop and the matching Selkies package.
ARG SELKIES_VERSION=2.2.1
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl geany ristretto tumbler xfce4 xfce4-terminal dbus-x11 xauth xvfb pulseaudio libgl1-mesa-dri && \
    arch="$(dpkg --print-architecture)" && \
    pkg="selkies-${SELKIES_VERSION}-ubuntu24.04-${arch}.deb" && \
    curl -fsSL "https://github.com/selkies-project/selkies/releases/download/${SELKIES_VERSION}/${pkg}" -o "/tmp/${pkg}" && \
    curl -fsSL "https://github.com/selkies-project/selkies/releases/download/${SELKIES_VERSION}/SHA256SUMS" -o /tmp/SHA256SUMS && \
    cd /tmp && grep -F "  ${pkg}" SHA256SUMS | sha256sum --check --strict && \
    apt-get install -y --no-install-recommends "./${pkg}" && \
    rm -f "/tmp/${pkg}" /tmp/SHA256SUMS && \
    rm -rf /var/lib/apt/lists/*

# Install Firefox from Mozilla's signed APT repository instead of Ubuntu's snap package.
RUN apt-get update && apt-get install -y --no-install-recommends gnupg && \
    install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc && \
    fingerprint="$(gpg --batch --show-keys --with-colons /etc/apt/keyrings/packages.mozilla.org.asc | awk -F: '$1 == "fpr" { print $10; exit }')" && \
    test "$fingerprint" = "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" && \
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main' > /etc/apt/sources.list.d/mozilla.list && \
    printf '%s\n' 'Package: firefox*' 'Pin: origin packages.mozilla.org' 'Pin-Priority: 1000' > /etc/apt/preferences.d/mozilla && \
    apt-get update && apt-get install -y --no-install-recommends firefox && \
    rm -rf /var/lib/apt/lists/*

# Ship the wallpaper and XFCE defaults; personal settings can override them.
COPY assets/xc_logo_alpha_channel.png /usr/share/xc-desktop/wallpaper.png
COPY assets/xfce4-desktop.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
COPY assets/shortcuts/ /usr/share/xc-desktop/shortcuts/
COPY scripts/xc-desktop-start /usr/local/bin/xc-desktop-start
RUN chmod 755 /usr/local/bin/xc-desktop-start

# Rename the default Ubuntu account and move its home before declaring the volume.
RUN usermod -l xc -d /home/xc -m ubuntu && groupmod -n xc ubuntu
VOLUME /home/xc
WORKDIR /home/xc

# Reset apt interactive mode for the final image.
ENV DEBIAN_FRONTEND=dialog

# The Selkies session manages the display, desktop and audio processes.
USER xc
ENV HOME=/home/xc USER=xc LOGNAME=xc
EXPOSE 8080
CMD ["/usr/local/bin/xc-desktop-start"]
