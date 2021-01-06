#!/bin/sh
old_pwd="$(pwd)"

latest_file="$(ls -t $HOME/.npm/_libvips | head -n1)"
full_file="$HOME/.npm/_libvips/$latest_file"
version="$( basename "$full_file" | cut -d"-" -f2)"
echo "Using libvips version $version from $full_file"
tmp="$(mktemp -d)"
echo "Using tmp dir: $tmp"
cd $tmp

# support both gz and br compression
decompress="gunzip"
ext=".gz"
if [ "${full_file##*.}" = "br" ]; then
    decompress="brotli -d --stdout"
    ext=".br"
fi
$decompress "$full_file" | tar xf -

# replace hardlinks by symlinks
hardlinks="$(find -type f -links +1)"
for target in $hardlinks; do
    for source in $( find -type f -samefile "$target"); do
	if [ "$source" != "$target" ]; then
	    echo "Converting hardlink to symlink: $source -> $target"
	    relpath="$(realpath --relative-to="$source" "$target")"
            rm "$source"
	    ln --relative --symbolic "$relpath" "$source"
	fi
    done
done

# Repackage as .tar.gz and .tar.br
tar_dir="${old_pwd}/v${version}"
mkdir -p "$tar_dir"
tar_file="$tar_dir/$( basename -s "$ext" "$full_file")"
echo Creating archive "$tar_file"
tar cf "$tar_file" *
echo Zip...
rm "$tar_file.gz"
gzip --keep "$tar_file"
echo Brotli...
rm -f "$tar_file.br"
brotli "$tar_file"
rm -f "$tar_file"

# cleanup tmp dir
cd "$old_pwd"
[ -n "$tmp" ] && rm -rf "$tmp"

