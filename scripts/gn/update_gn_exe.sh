#!/bin/bash
rm *.zip
rm -rf linux/* linux/.cipdpkg/
rm -rf macos/* macos/.cipdpkg/
rm -rf windows/* windows/.cipdpkg/

curl -L -o gn_linux.zip https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/latest
curl -L -o gn_macos.zip https://chrome-infra-packages.appspot.com/dl/gn/gn/mac-arm64/+/latest
curl -L -o gn_win.zip https://chrome-infra-packages.appspot.com/dl/gn/gn/windows-amd64/+/latest

unzip -q gn_linux.zip -d linux
unzip -q gn_macos.zip -d macos
unzip -q gn_win.zip -d windows

rm *.zip

macos/gn --version >version.txt
