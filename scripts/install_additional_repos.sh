#!/usr/bin/env bash
#
# Install additional YUM repositories, typically used for security patches.
# The format of ADDITIONAL_YUM_REPOS is: "repo=patches-repo,name=Install patches,baseurl=http://amazonlinux.$awsregion.$awsdomain/xxxx,priority=10"
# which will create the file '/etc/yum.repos.d/patches-repo.repo' having the following content:
# ```
# [patches-repo]
# name=Install patches
# baseurl=http://amazonlinux.$awsregion.$awsdomain/xxxx
# priority=10
# ```
# Note that priority is optional, but the other parameters are required. Multiple yum repos can be specified, each one separated by ';'
 
set -o pipefail
set -o nounset
set -o errexit

function warn {
	if ! eval "$@"; then
		echo >&2 "WARNING: command failed \"$@\""
	fi
}

warn "sudo apt-add-repository ppa:ansible/ansible -y"
