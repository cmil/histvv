#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

use XML::LibXML;

BEGIN {
	use_ok( 'Histvv::Search' );
}

can_ok('Histvv::Search', 'strip_text');

my $xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<vv xmlns="$Histvv::XMLNS">
  <foo> foo <seite>2</seite>bar <xyz>baz</xyz></foo>
  <baz><scil text="quux">qux</scil></baz>
</vv>
EOF

my $doc = XML::LibXML->new->parse_string($xml);

my ($foo) = $doc->getElementsByLocalName('foo');
is( Histvv::Search::strip_text($foo),
    'foo bar baz', "strip_text() removes 'seite'" );
is( Histvv::Search::strip_text($foo, 0, ['xyz']),
    'foo 2bar', "strip_text() removes arbitrary element, keeps 'seite'" );
is( Histvv::Search::strip_text($foo, 0, ['xyz', 'seite']),
    'foo bar', "strip_text() removes arbitrary element including 'seite'" );

my ($baz) = $doc->getElementsByLocalName('baz');
is( Histvv::Search::strip_text($baz),
    'qux', "strip_text(\$node) does not expand 'scil'" );
is( Histvv::Search::strip_text($baz, 1),
    'qux [quux]', "strip_text(\$node, 1) expands 'scil'" );
is( Histvv::Search::strip_text($baz, 2),
    '[quux]', "strip_text(\$node, 2) replaces 'scil'" );

is($doc->toString(1), $xml, 'strip_text() keeps source intact');

#diag($doc->toString());
#diag($txt);
