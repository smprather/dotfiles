#!/bin/bash
repo_dir=$(git rev-parse --show-toplevel)
echo "Dotfiles repo base directory: $repo_dir"
cd ~
ln -s $repo_dir/bash_env/bashrc .bashrc
ln -s $repo_dir/bash_env/bashrc .bashrc
