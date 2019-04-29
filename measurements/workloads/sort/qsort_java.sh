#!/bin/sh
unset _JAVA_OPTIONS
cd $(dirname $(realpath $0))
/usr/bin/java Sort
