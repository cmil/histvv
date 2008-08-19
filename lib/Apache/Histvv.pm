package Apache::Histvv;

use strict;
use warnings;

=head1 NAME

Apache::Histvv - the Histvv Apache handler

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  PerlModule Apache::Histvv
  <Location /vv>
    SetHandler perl-script
    PerlResponseHandler Apache::Histvv
  </Location>

=head1 DESCRIPTION

FIXME

=cut

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Request ();
use XML::LibXML ();
use XML::LibXSLT ();
use Histvv::Db ();

use Apache2::Const -compile => qw(:common);

my $Xp = XML::LibXML->new();
my $Xt = XML::LibXSLT->new();

my %Queries = (
    index => q{
declare namespace v = "http://histvv.uni-leipzig.de/ns/2007";
<index>
{
for $d in collection()/v:vv
let $k := $d/v:kopf
let $sem := if ($k/v:semester = "Winter") then "ws" else "ss"
return
<vv name="{concat($k/v:beginn/v:jahr, "-", $sem)}" >
  <titel>{concat($k/v:semester, "semester ", $k/v:beginn/v:jahr)}</titel>
  <vnum>{count($d//v:veranstaltung)}</vnum>
  {if ($k/v:status/@komplett = "ja") then <komplett/> else ''}
</vv>
}
</index>
},

    semester => q{
declare namespace v = "http://histvv.uni-leipzig.de/ns/2007";
for $d in collection()/v:vv
let $k := $d/v:kopf
where $k/v:status[@komplett = "ja"]
  and $k/v:semester = "%s"
  and $k/v:beginn/v:jahr = "%d"
return $d
},

    dozenten => q{
declare namespace v = "http://histvv.uni-leipzig.de/ns/2007";
for $d in collection()/v:dozentenliste[1]
return $d
},

    dozent => <<'EOT',
declare namespace v = "http://histvv.uni-leipzig.de/ns/2007";

let $id := "%s"

let $daten := collection()/v:dozentenliste/v:dozent[@xml:id=$id]
let $stellen := collection()/v:vv[v:kopf/v:status/@komplett]
  //v:dozent[@ref=$id]

return
<report>
  {$daten}
  <stellen >
  {
    for $d in $stellen
    let $node := $d/..
    let $s := $node/preceding::v:seite[1]
    let $snr := if ($s)
                then (if ($s/@nr) then $s/@nr else $s/string())
                else '1'
    let $kopf := $d/ancestor::v:vv/v:kopf
    let $sem := $kopf/v:semester/string()
    let $jahr := $kopf/v:beginn/v:jahr/string()
    return
    <stelle semester="{$sem}" jahr="{$jahr}" seite="{$snr}">
    {$node}
    </stelle>
  }
  </stellen>
</report>
EOT

    dozentenlookup => <<'EOT',
declare namespace v = "http://histvv.uni-leipzig.de/ns/2007";

let $name := "%s"

let $stellen := collection()/v:vv[v:kopf/v:status/@komplett]
  //v:dozent[not(@ref) and %s=$name]

return
<report>
  <name>{$name}</name>
  <stellen >
  {
    for $d in $stellen
    let $node := $d/..
    let $s := $node/preceding::v:seite[1]
    let $snr := if ($s)
                then (if ($s/@nr) then $s/@nr else $s/string())
                else '1'
    let $kopf := $d/ancestor::v:vv/v:kopf
    let $sem := $kopf/v:semester/string()
    let $jahr := $kopf/v:beginn/v:jahr/string()
    return
    <stelle semester="{$sem}" jahr="{$jahr}" seite="{$snr}">
    {$node}
    </stelle>
  }
  </stellen>
</report>
EOT

);


sub handler {
    my $r = shift;

    my $dbfile = $r->dir_config('HISTVV_DB');
    my $xslfile = $r->dir_config('HISTVV_XSL');
    my $cssurl = $r->dir_config('HISTVV_CSS');

    (my $loc = $r->location) =~ s/\/$//;
    (my $url = $r->uri) =~ s/^$loc//;

    my $xquery;

    if ($loc eq '/dozenten') {
        if ($url =~ /^\/(index\.html)?$/) {
            $xquery = $Queries{dozenten};
        } elsif ($url =~ /^\/lookup$/) {
            my $rq = Apache2::Request->new($r);
            my $name = $rq->param('name') || return Apache2::Const::DECLINED;
            $name =~ s/"/""/g;
            my $query = $name =~ /\s/ ? 'normalize-space(v:nachname)' : 'v:nachname';
            $xquery = sprintf $Queries{dozentenlookup}, $name, $query;
        } elsif ($url =~ /^\/([-_a-z0-9]+)\.html$/) {
            $xquery = sprintf $Queries{dozent}, $1;
        } else {
            return Apache2::Const::DECLINED;
        }
    } elsif ($loc eq '/vv') {
        if ( $url =~ /^\/([0-9]{4})-(ws|ss)\.html$/ ) { # single VV
            my $year = $1;
            my $semester = $2 eq 'ws' ? 'Winter' : 'Sommer';
            $xquery = sprintf $Queries{semester}, $semester, $year;
        }
        elsif ( $url =~ /^\/(index\.html)?$/ ) { # list of VVs
            $xquery = $Queries{index};
        }
        else {
            return Apache2::Const::DECLINED;
        }
    }

    my $db = Histvv::Db->new( $dbfile );
    my @results = $db->query_all( $xquery );
    return Apache2::Const::NOT_FOUND unless @results > 0;

    my $xml = $results[0];
    my $xmldom = $Xp->parse_string($xml);
    my $xsldom = $Xp->parse_file($xslfile);
    my $stylesheet = $Xt->parse_stylesheet($xsldom);

    my %params = ( cssurl => "'$cssurl'" );

    my $html;
    eval { $html = $stylesheet->transform($xmldom, %params) };
    if ($@) {
        warn "$@\n";
        return Apache2::Const::SERVER_ERROR;
    }

    if (0) {
        $r->content_type('text/plain');
        print "$xml";
    } else {
        $r->content_type('application/xhtml+xml');
        print $stylesheet->output_as_bytes($html);
    }

    print "\n\n";
    print "<!--\n";
    print "URI: " . $r->uri . "\n";
    print "Location: " . $r->location . "\n";
    print "URL: " . $url . "\n";
    print "ARGS: " . $r->args . "\n";
    print "DB: $dbfile\n";
    print "XSL: $xslfile\n";
    print "CSS: $cssurl\n";
    print "$xquery\n";
    #print Dumper \%ENV;
    print "-->\n";

    return Apache2::Const::OK;
}

=head1 AUTHOR

Carsten Milling, C<< <cmil at hashtable.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Carsten Milling, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
