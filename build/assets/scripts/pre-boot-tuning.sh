#!/usr/bin/env bash

set -euo pipefail

SYSTEM_CONFIG_FILE="/etc/systemd/system.conf"
SYSTEM_CONFIG_CUSTOM_FILE="/etc/systemd/system.conf.d/setAffinity.conf"

if [ -f /etc/sysconfig/irqbalance ] && [ -f ${SYSTEM_CONFIG_CUSTOM_FILE} ]  && rpm-ostree status -b | grep -q -e "${SYSTEM_CONFIG_FILE} ${SYSTEM_CONFIG_CUSTOM_FILE}" && egrep -wq "^IRQBALANCE_BANNED_CPUS=${RESERVED_CPU_MASK_INVERT}" /etc/sysconfig/irqbalance; then
    echo "Pre boot tuning configuration already applied"
else
    #Set IRQ balance banned cpus
    if [ ! -f /etc/sysconfig/irqbalance ]; then
        touch /etc/sysconfig/irqbalance
    fi

    if grep -ls "IRQBALANCE_BANNED_CPUS=" /etc/sysconfig/irqbalance; then
        sed -i "s/^.*IRQBALANCE_BANNED_CPUS=.*$/IRQBALANCE_BANNED_CPUS=${RESERVED_CPU_MASK_INVERT}/" /etc/sysconfig/irqbalance
    else
        echo "IRQBALANCE_BANNED_CPUS=${RESERVED_CPU_MASK_INVERT}" >>/etc/sysconfig/irqbalance
    fi

    rpm-ostree initramfs --enable --arg=-I --arg="${SYSTEM_CONFIG_FILE} ${SYSTEM_CONFIG_CUSTOM_FILE}" 

    touch /var/reboot
fi
