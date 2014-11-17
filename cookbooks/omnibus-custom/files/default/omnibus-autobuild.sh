#!/bin/bash -l

source ~/.bashrc
exec ruby /usr/local/share/omnibus-autobuild.rb "$@"
