#!/bin/sh
set -eu

cd "$(dirname "$(realpath "$0")")"

rm -rf other_repos
rm -rf generated_bins
