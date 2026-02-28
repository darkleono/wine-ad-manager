FROM rockylinux:9

# Install required dependencies for Autodesk NLM
RUN dnf update -y && \
    dnf install -y \
    libnsl \
    procps-ng \
    iproute \
    && dnf clean all

# Fixed for EL9: Create LSB loader symlink (deprecated in Rocky 9 but needed by NLM)
RUN ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3

# Create temporary directory for the RPM
WORKDIR /tmp

# Copy the RPM file from the bin folder
COPY bin/nlm11.19.4.1_ipv4_ipv6_linux64.rpm .

# Install the NLM package
# This will create /opt/flexnetserver/ with lmgrd, adskflex, etc.
RUN rpm -ivh nlm11.19.4.1_ipv4_ipv6_linux64.rpm && \
    rm nlm11.19.4.1_ipv4_ipv6_linux64.rpm

# Expose FlexLM ports
EXPOSE 27000 2080

WORKDIR /opt/flexnetserver

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
