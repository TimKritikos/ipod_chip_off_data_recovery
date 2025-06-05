#!/bin/sh
set -eu

cd "$(dirname "$(realpath "$0")")"

rm -rf other_repos/*

mv bins/device_infos .
rm -rf bins/*
mv  device_infos bins/
