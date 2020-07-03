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

in="aurora-2.0.3-plugins"
for x in `ls $in/`; do
    if [ ! -d "$in/$x" ]; then
        continue
    fi

    p="$in/$x"
    ref="$in.ref/$x"

    rm "$tmp" -rf || rm "$tmp/*" -f || exit 1
    mkdir -p "$tmp" || exit 1
    
    echo "==[ $p ]=="
    $perl $conv --in "$p" --out "$tmp"
    if [ "$?" != "0" ]; then
        echo "=====> ERROR during conversion!"
        error=1
    fi

    $perl compare_ini.pl "$ref/plugin.ini" "$tmp/plugin.ini"
    if [ "$?" != "0" ]; then
        echo "=====> ERROR while checking against reference!"
        error=1
    fi
    
    rm "$tmp" -rf || rm "$tmp/*" -f || exit 1
    echo ""
    echo ""
done

if [ "$error" == "0" ]; then
    echo "Finished with no errors :)"
else
    echo "FINISHED WITH ERRORS !! :("
fi
exit $error
