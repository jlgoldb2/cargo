#!/bin/bash

set -x
set -e

if [ "${TRAVIS_OS_NAME}" = "osx" ] || [ "${PLATFORM}" = "mac" ] || [ "`uname`" = "Darwin" ]; then
    target=apple-darwin
elif [ "${OS}" = "Windows_NT" ] || [ "${PLATFORM}" = "win" ]; then
    windows=1
else
    target=unknown-linux-gnu
fi

if [ "${TRAVIS}" = "true" ] && [ "${target}" = "unknown-linux-gnu" ]; then
    # Install a 32-bit compiler for linux
    sudo apt-get update
    if [ "${BITS}" = "32" ]; then
        sudo apt-get install libssl-dev:i386
    fi
    sudo apt-get install g++-multilib lib32stdc++6
fi

url=https://static-rust-lang-org.s3.amazonaws.com/dist/`cat src/rustversion.txt`

# Install both 64 and 32 bit libraries. Apparently travis barfs if you try to
# just install the right ones? This should enable cross compilation in the
# future anyway.
if [ -z "${windows}" ]; then
    rm -rf rustc *.tar.gz
    curl -O $url/rust-nightly-i686-$target.tar.gz
    curl -O $url/rust-nightly-x86_64-$target.tar.gz
    tar xfz rust-nightly-i686-$target.tar.gz
    tar xfz rust-nightly-x86_64-$target.tar.gz

    if [ "${BITS}" = "32" ]; then
        src=x86_64
        dst=i686
    else
        src=i686
        dst=x86_64
    fi
    cp -r rust-nightly-$src-$target/lib/rustlib/$src-$target \
          rust-nightly-$dst-$target/lib/rustlib
    (cd rust-nightly-$dst-$target && \
     find lib/rustlib/$src-$target/lib -type f >> \
     lib/rustlib/manifest.in)

    ./rust-nightly-$dst-$target/install.sh --prefix=rustc
    rm -rf rust-nightly-$src-$target
    rm -rf rust-nightly-$dst-$target
    rm -f rust-nightly-i686-$target.tar.gz
    rm -f rust-nightly-x86_64-$target.tar.gz
else
    rm -rf rustc *.exe
    if [ "${BITS}" = "64" ]; then
        triple=x86_64-pc-windows-gnu
    else
        triple=i686-pc-windows-gnu
    fi
    curl -O $url/rust-nightly-$triple.exe
    innounp -y -x rust-nightly-$triple.exe
    mv '{app}' rustc
    # Don't use the bundled gcc, see rust-lang/rust#17442
    rm -rf rustc/bin/rustlib/$triple/bin
    # Don't use bundled gcc libs, see rust-lang/rust#19519
    rm -rf rustc/bin/rustlib/$triple/libmingw*.a
    rm -f rust-nightly-$triple.exe
fi

set +x
