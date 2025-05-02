#!/bin/bash

wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
tar xvzf go1.24.2.linux-amd64.tar.gz
sudo mv go /etc/local
echo 'export PATH=$PATH:/usr/local/go/bin' >>$HOME/.bashrc
