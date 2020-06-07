package NetParser;

use strict;
use warnings;
use XML::LibXML::Reader;

use Tools;
use Net;

my $stopParsing = 0;
my $verbose = 0;

sub parse {
    my $xml_file = shift;
    $stopParsing = 0;
    die "xml file does not exist\n" if not -f $xml_file;

    my $xml = XML::LibXML::Reader->new(location => $xml_file);
    
    if (not $xml) {
        main::error("Error parsing NetList XML!\n");
        return 0;
    }

    while (not $stopParsing and $xml->read()) {
        if ($xml->name eq "Algorithm") {
            parseAlgorithm($xml);
        }
    }

    return $stopParsing ? 0 : 1;
}

sub printNode {
    my $xml = shift;
    printf "%d %d %s %d\n", ($xml->depth, $xml->nodeType, $xml->name, $xml->isEmptyElement);
}

sub skipNonElements {
    my $xml = shift;
    while (not $stopParsing and $xml->nodeType != XML_READER_TYPE_ELEMENT and $xml->nodeType != XML_READER_TYPE_END_ELEMENT) {
        last if not $xml->read;
    }
}

sub parseError {
    my $xml = shift;
    my $str = "Error parsing NetList at line " . $xml->lineNumber() . ":";
    while (my $x = shift) {
        $str .= " " . $x;
    }
    main::error($str);
    $stopParsing = 1;
}

sub parseAlgorithm {
    my $xml = shift;

    # We expect to enter with the opening tag, e.g.
    # <Algorithm name="..." friendlyname="..." cell="Phase 1 ">
    my $cell = $xml->getAttribute("cell") or return parseError($xml, "Algorithm-tag is missing attribute 'cell'!\n");
    $cell = Tools::normalize($cell);
    
    print "$cell ", $xml->nodeType, "\n" if $verbose;
    my $algo = Net::addAlgo($cell);

    # Now come all the <Link pin="..." dir="(in|out)" link="Link123" />-tags
    while (not $stopParsing and $xml->read()) {
        skipNonElements($xml);
        last if $xml->name ne "Link";
        my $dir = $xml->getAttribute("dir") or return parseError($xml, "Link-tag has no attribute 'dir'!\n");
        my $id = $xml->getAttribute("link") or return parseError($xml, "Link-tag has no attribute 'link'!\n");
        $id =~ s/^Link//;
        $algo->addLink($dir, int($id));
    }

    # we finish at the closing </Algorithm>:
    if ($xml->name ne "Algorithm") {
        return parseError($xml, "Algorithm did not end on closing tag, but '", $xml->name, "' instead!\n");
    }

    return $algo;
}
1;
