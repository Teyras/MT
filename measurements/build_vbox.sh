#!/bin/sh

TEMPLATE_FILE=$(dirname $0)/vagrant/template.box

if ! [ -f $TEMPLATE_FILE ]; then
	VAGRANT_TEMPLATE="VAGRANT_CWD=$(dirname $0)/vagrant/vbox_template vagrant"

	$VAGRANT_TEMPLATE up
	$VAGRANT_TEMPLATE package
	$VAGRANT_TEMPLATE destroy
	mv package.box $TEMPLATE_FILE
fi

VAGRANT="env VAGRANT_CWD=$(dirname $0)/vagrant/vbox_multi vagrant"

$VAGRANT destroy -f '/vbox_.*/'
$VAGRANT up '/vbox_.*/'
$VAGRANT suspend '/vbox_.*/'
