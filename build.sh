#!/bin/sh -xe

cd $HOME
rm -rf src
mkdir src
cd $HOME/src

git clone git@github.com:Nexenta/zfsxx-nza-kernel.git new-nza-ws
git clone git@github.com:Nexenta/zfsxx-nza-closed.git new-nza-ws/usr/nza-closed

cd new-nza-ws
wget -c http://dlc.sun.com/osol/on/downloads/20100817/on-closed-bins.i386.tar.bz2 http://dlc.sun.com/osol/on/downloads/20100817/on-closed-bins-nd.i386.tar.bz2
tar xpf on-closed-bins.i386.tar.bz2
tar xpf on-closed-bins-nd.i386.tar.bz2

cp $HOME/scripts/nza.sh .
ln -s usr/src/tools/scripts/nightly.sh

./nightly.sh ./nza.sh
