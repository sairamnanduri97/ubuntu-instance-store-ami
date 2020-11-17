#!/usr/bin/env bash
#
# Clean up additional YUM repositories, typically used for security patches.
# The format of ADDITIONAL_YUM_REPOS is: "repo=patches-repo,name=Install patches,baseurl=http://amazonlinux.$awsregion.$awsdomain/xxxx,priority=10"
# Multiple yum repos can be specified, separated by ';'

set -o pipefail
set -o nounset
set -o errexit

function warn {
	if ! eval "$@"; then
		echo >&2 "WARNING: command failed \"$@\""
	fi
}


warn "sudo apt-add-repository -r ppa:ansible/ansible -y"
