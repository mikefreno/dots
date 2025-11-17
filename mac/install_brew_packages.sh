#!/bin/bash

# Homebrew Package Installation Script
# This script installs all formulae and casks for macOS dotfiles setup

set -e  # Exit on error

echo "🍺 Starting Homebrew package installation..."
echo "================================================"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install it first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Update Homebrew
echo ""
echo "📦 Updating Homebrew..."
brew update

# Tap additional repositories
echo ""
echo "🔧 Adding taps..."
brew tap felixkratz/formulae
brew tap koekeishiya/formulae
brew tap hashicorp/tap
brew tap pkgxdev/made
brew tap tursodatabase/tap
brew tap ungive/media-control
brew tap zegervdv/zathura

# Install formulae
echo ""
echo "📦 Installing formulae..."
brew install \
    abseil \
    adwaita-icon-theme \
    aom \
    apr \
    apr-util \
    argon2 \
    aribb24 \
    at-spi2-core \
    autoconf \
    automake \
    bear \
    berkeley-db@5 \
    bfg \
    binaryen \
    boost \
    borders \
    brew-cask-completion \
    brotli \
    btop \
    c-ares \
    ca-certificates \
    cairo \
    cask \
    cjson \
    cloc \
    cmake \
    cmocka \
    cocoapods \
    coreutils \
    curl \
    cyrus-sasl \
    dav1d \
    dbus \
    desktop-file-utils \
    double-conversion \
    edencommon \
    emacs \
    fastfetch \
    fb303 \
    fbthrift \
    fd \
    ffmpeg \
    fizz \
    flac \
    fmt \
    folly \
    fontconfig \
    freetds \
    freetype \
    frei0r \
    fribidi \
    gcc \
    gd \
    gdbm \
    gdk-pixbuf \
    gettext \
    gflags \
    gh \
    ghostscript \
    giflib \
    girara \
    git \
    glib \
    glog \
    gmp \
    gnu-sed \
    gnutls \
    go \
    graphite2 \
    grpc \
    gsettings-desktop-schemas \
    gsl \
    gtk+3 \
    gtk-mac-integration \
    gumbo-parser \
    harfbuzz \
    hicolor-icon-theme \
    highway \
    icu4c@76 \
    icu4c@77 \
    imath \
    intltool \
    isl \
    jbig2dec \
    jpeg-turbo \
    jpeg-xl \
    jq \
    json-c \
    json-glib \
    krb5 \
    lame \
    latexml \
    leptonica \
    libarchive \
    libass \
    libavif \
    libb2 \
    libbluray \
    libcbor \
    libdeflate \
    libepoxy \
    libevent \
    libfido2 \
    libidn \
    libidn2 \
    libmagic \
    libmicrohttpd \
    libmpc \
    libnghttp2 \
    libnghttp3 \
    libngtcp2 \
    libnotify \
    libogg \
    libomp \
    libpng \
    libpq \
    libpthread-stubs \
    librist \
    librsvg \
    libsamplerate \
    libsndfile \
    libsodium \
    libsoxr \
    libssh \
    libssh2 \
    libtasn1 \
    libtiff \
    libtool \
    libudfread \
    libunibreak \
    libunistring \
    libuv \
    libvidstab \
    libvmaf \
    libvorbis \
    libvpx \
    libx11 \
    libxau \
    libxcb \
    libxdmcp \
    libxext \
    libxfixes \
    libxi \
    libxrender \
    libxtst \
    libyaml \
    libzip \
    little-cms2 \
    llama.cpp \
    lld \
    lld@20 \
    llvm \
    llvm@20 \
    lpeg \
    lua \
    lua-language-server \
    luajit \
    luarocks \
    luv \
    lz4 \
    lzo \
    m4 \
    maven \
    mbedtls \
    media-control \
    mpdecimal \
    mpfr \
    mpg123 \
    mujs \
    mupdf \
    mysql \
    ncurses \
    neovim \
    net-snmp \
    nettle \
    nlohmann-json \
    nnn \
    node \
    ocaml \
    oniguruma \
    opam \
    opencode \
    opencore-amr \
    openexr \
    openjdk \
    openjpeg \
    openjph \
    openldap \
    openssl@1.1 \
    openssl@3 \
    opus \
    p11-kit \
    pango \
    pcre2 \
    perl \
    php \
    pixman \
    pkgconf \
    pkgx \
    pnpm \
    popt \
    postgresql@14 \
    protobuf \
    protobuf@29 \
    python-packaging \
    python@3.10 \
    python@3.13 \
    python@3.14 \
    rav1e \
    re2 \
    readline \
    ripgrep \
    rsync \
    rtmpdump \
    rubberband \
    ruby \
    rust-analyzer \
    sdl2 \
    simdjson \
    sketchybar \
    skhd \
    snappy \
    spdlog \
    speex \
    sqld \
    sqlite \
    srt \
    starship \
    stylua \
    svt-av1 \
    switchaudio-osx \
    tesseract \
    texlab \
    theora \
    tidy-html5 \
    tmux \
    tree-sitter \
    turso \
    unbound \
    unibilium \
    unixodbc \
    utf8proc \
    uvwasi \
    vault \
    wangle \
    watchman \
    webp \
    wget \
    wireguard-go \
    x264 \
    x265 \
    xorgproto \
    xvid \
    xxhash \
    xz \
    yabai \
    yyjson \
    z3 \
    zathura \
    zathura-pdf-mupdf \
    zeromq \
    zig \
    zimg \
    zlib \
    zoxide \
    zsh-autosuggestions \
    zsh-fast-syntax-highlighting \
    zstd

# Install casks
echo ""
echo "🖥️  Installing casks..."
brew install --cask \
    android-platform-tools \
    android-studio \
    bitwarden \
    blender \
    cutter \
    discord \
    flutter \
    font-fira-code \
    font-hack-nerd-font \
    font-jetbrains-mono \
    font-jetbrains-mono-nerd-font \
    font-sauce-code-pro-nerd-font \
    font-sf-mono \
    font-sf-pro \
    ghostty \
    gstreamer-runtime \
    hex-fiend \
    libreoffice \
    lm-studio \
    love \
    maccy \
    macfuse \
    mactex \
    meetingbar \
    platypus \
    plex \
    protonvpn \
    sf-symbols \
    shortcat \
    skim \
    sloth \
    youtube-music \
    zen \
    zoom

# Cleanup
echo ""
echo "🧹 Cleaning up..."
brew cleanup

echo ""
echo "================================================"
echo "✅ Installation complete!"
echo ""
echo "📝 Note: Some packages may require additional configuration."
echo "   Check individual package documentation for setup instructions."
