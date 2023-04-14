#! /usr/bin/bash

CLONE_PACKAGES=(
  'grimblast-git'
  'libdisplay-info'
  'mkinitcpio-openswap'
  'google-chrome'
  'libdisplay-info.so'
  'nordic-theme'
  'hyprland-bin'
  'nwg-look-bin'
  'pamixer'
  'papirus-icon-theme'
  'sddm-git'
  'swaybg'
  'swaylock-effects'
  'ttf-comfortaa'
  'ttf-icomoon-feather'
  'waybar-hyprland'
  'wlogout'
)

FAILED=()
ALREADY_BUILT=()

function register_failed() {
  FAILED+=("$1")
}
function register_already_built() {
  ALREADY_BUILT+=("$1")
}
function build() {
  dir=$1
  cd $dir
  rm -r src pkg 2> /dev/null
  makepkg -d --skippgpcheck
  status=$?
  if [ "$status" == "13" ]; then
    register_already_built $dir
    echo "$dir already built"
  fi
  if ( [ $status -ne 13 ] && [ $status -ne 0 ] ); then
    register_failed $dir
    echo "Failed to build $dir"
  fi
  for file in *".pkg.tar.zst"; do
    cp $file ../build
  done
  cd ..
}

if [ "$1" == "cleanup" ]; then
  for dir in *; do
    if [ -d $dir ]; then
      if [ -f "$dir/PKGBUILD" ]; then
        echo "Cleanup $dir"
        cd $dir
        rm -rf src pkg *.pkg.tar.zst
        cd ..
      fi
    fi
  done
  for pkg in "${CLONE_PACKAGES[@]}"; do
    echo "Removing $pkg"
    rm -rf $pkg
  done
  exit 0
fi

if [ "$1" != "" ]; then
  mkdir build
  build $1
  cd build
  repo-add radulinux.db.tar.gz *.pkg.tar.zst
  exit
fi  

mkdir build || rm -r build && mkdir build

for pkg in "${CLONE_PACKAGES[@]}"; do
  echo "Cloning $pkg"
  git clone https://aur.archlinux.org/$pkg &> /dev/null
done

for dir in *; do
  if [ -d $dir ]; then
    if [ -f "$dir/PKGBUILD" ]; then
      echo "Building $dir"
      build $dir
    fi
  fi
done

cd build
repo-add radulinux.db.tar.gz *.pkg.tar.zst
if [ "${#ALREADY_BUILT}" -ne 0 ]; then
  echo "The following packages were already built:"
  for pkg in "${ALREADY_BUILT[@]}"; do
    echo $pkg
  done
fi
if [ "${#FAILED}" -ne 0 ]; then
  echo "Failed to build the following packages:"
  for pkg in "${FAILED[@]}"; do
    echo $pkg
  done
fi