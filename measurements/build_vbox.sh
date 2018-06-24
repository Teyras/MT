#!/bin/sh

VAGRANT="VAGRANT_CWD=$(dirname $0)/vagrant/vbox_multi vagrant"

$VAGRANT destroy -f '/vbox_.*/'
$VAGRANT up '/vbox_.*/'
$VAGRANT suspend '/vbox_.*/'
