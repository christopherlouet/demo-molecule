FROM rockylinux:8.8
MAINTAINER Christopher LOUËT

ENV container docker
# Update time zone
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Installing dnf packages
RUN dnf makecache && \
    dnf --assumeyes install bash systemd procps sudo iproute net-tools /usr/bin/dnf-3 \
    /usr/bin/python3 /usr/bin/python3-config \
    vim curl && \
    dnf clean all;

RUN ([ -d /lib/systemd/system/sysinit.target.wants ] && cd /lib/systemd/system/sysinit.target.wants/ && for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/sbin/init"]
