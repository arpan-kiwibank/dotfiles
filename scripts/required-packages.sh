#! /bin/bash

set -ue

source $(dirname "${BASH_SOURCE[0]:-$0}")/utils.sh

distro=$(whichdistro)
if [[ $distro == "redhat" ]]; then
	checkinstall findutils
elif
	echo "os not compatible"; then
	exit 1
	return
fi