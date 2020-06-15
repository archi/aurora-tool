set -u
perl=/c/Strawberry/perl/bin/perl
conv=../src/converter.pl

function filter_ini {
    cat "$1" | tr -d '\n\r' 
}

if [ ! -e "$perl" ]; then
    perl=$(which perl)
    if [ "$?" != "0" ]; then
        echo "Could not find perl!"
        exit 1
    fi
fi

if [ ! -e "$conv" ]; then
    echo "Could not find converter.pl!"
    exit 1
fi

echo "Using perl: $perl"
echo "Using converter: $conv"

tmp=test-tmp
error=0

    p="aurora-2.0.3-plugins/8channels"
    ref="aurora-2.0.3-plugins.ref/8channels"

    rm "$tmp" -rf || rm "$tmp/*" -f || exit 1
    mkdir -p "$tmp" || exit 1
    
    echo "==[ $p ]=="
    $perl $conv --in "$p" --out "$tmp"
    if [ "$?" != "0" ]; then
        echo "=====> ERROR in conversion!"
        error=1
    fi

    $perl compare_ini.pl "$ref/plugin.ini" "$tmp/plugin.ini"

exit $error
