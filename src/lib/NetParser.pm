package NetParser;

use strict;
use warnings;
use XML::LibXML::Reader;

use Tools;
use NetAlgo;

my $verbose = 0;

sub parse {
    my $xml_file = shift;
    my $collectedData = shift;
    
    die "xml file does not exist\n" if not -f $xml_file;

    my $xml = XML::LibXML::Reader->new(location => $xml_file);
    
    if (not $xml) {
        return parseError($xml, "Could not create XML Reader!");
    }

    while ($xml->read()) {
        next if (not $xml->name eq "Algorithm");

        # We expect to enter with the opening tag, e.g.
        # <Algorithm name="..." friendlyname="..." cell="Phase 1 ">
        my $cell = $xml->getAttribute("cell") or return parseError($xml, "Algorithm-tag is missing attribute 'cell'!");
        $cell = Tools::normalize($cell);
        
        my $algo = $collectedData->addAlgo($cell);

        # Now come all the <Link pin="..." dir="(in|out)" link="Link123" />-tags
        while ($xml->read()) {
            skipNonElements($xml);
            last if $xml->name ne "Link";
            my $dir = $xml->getAttribute("dir") or return parseError($xml, "Link-tag has no attribute 'dir'!");
            my $id = $xml->getAttribute("link") or return parseError($xml, "Link-tag has no attribute 'link'!");
            $id =~ s/^Link//;
            $collectedData->addLink($algo, $dir, int($id));
        }

        # we finish at the closing </Algorithm>:
        if ($xml->name ne "Algorithm") {
            return parseError($xml, "Algorithm did not end on closing tag, but '", $xml->name, "' instead!");
        }
    }

    return 1;
}

sub skipNonElements {
    my $xml = shift;
    while ($xml->nodeType != XML_READER_TYPE_ELEMENT and $xml->nodeType != XML_READER_TYPE_END_ELEMENT) {
        last if not $xml->read;
    }
}

sub parseError {
    my $xml = shift;
    my $str = "Error parsing NetList at line " . (defined $xml ? $xml->lineNumber() : "?unknown?") . ":";
    while (my $x = shift) {
        $str .= " " . $x;
    }
    # TODO pass the error to the user
    # main::error($str);
    print $str, "\n";
    return 0;
}

1;
