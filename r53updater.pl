#!/usr/bin/perl -w

=license
Copyright (C) 2014 Daniel J Minear

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
=cut

use strict;
use Net::Amazon::Route53;
use Data::Dumper;
use JSON qw/encode_json/;
use JSON::Parse ':all';
use FileHandle;
use Net::Address::IP::Local;

my $jsonfilename = "r53updater.json";
my $keys = json_file_to_perl( $jsonfilename );

# need to figure out my IP address here
my $currentIP = getIPaddress( { "method" => "public",
								"param" => "eth0" } );

if ($keys->{"lastIP"} eq $currentIP) {	# no change
	exit 0;
} else {
	# store the new one
	$keys->{"lastIP"} = $currentIP;
	
	# and write over existing json file
	my $jsontext = encode_json( $keys );
	my $fh = FileHandle->new( $jsonfilename, "w" ) || die "Cannot write $jsonfilename: $!";
	print $fh $jsontext;
	undef $fh;
}
		
my $route53 = Net::Amazon::Route53->new( "id" => $keys->{id}, "key" => $keys->{key} );
foreach my $domain (@{$keys->{domains}}) {
	my @zones = $route53->get_hosted_zones("$domain."); 	# yup, ending period there
	my $zone = $zones[0];
	if (! defined $zone ) {
		warn "zone $domain not known, skipping";
		next;
	}

	# use the Net::Amazon::Route53::HostedZone object
	print "Zone " . $zone->name . "\n";
	my @sets = $zone->resource_record_sets;
	my $set = $sets[0];

	my @arecords = grep { $_->{type} eq "A" } @{$set};

	# there should only be 1 A record
	if (@arecords != 1 ) {
		warn "There are more than 1 A record";
		next;
	}

	my $s= $arecords[0];
	#print Dumper($s);
	print $s->{type} . ":" . $s->{name} . ":" . join (" ", @{$s->{values}}) . "\n";

	if (${$s->{values}}[0] eq $keys->{"lastIP"}) {
		print "Domain $domain has same A record, skipping.\n";
		next;
	}

	my $update = Net::Amazon::Route53::ResourceRecordSet::Change->new(
		route53 => $route53,
		hostedzone => $zone,
		name => $domain,
		ttl => $s->{ttl},
		type => "A",
		values => [ $currentIP ],
		original_values => $s->{values},
	);
	#print Dumper($update);
	$update->change();
}

sub getIPaddress {
	my $ref = shift;
	my $method = $ref->{method};
	my $param = $ref->{param};

	print "method $method with param $param\n";

	if ($method =~ /if/ ) {
		# TODO take the param and get the IP address for that interface
		return "192.168.0.1";
	} elsif ( $method =~ /public/ ) {
		my $address  = Net::Address::IP::Local->public;
		return $address;
	} else {
		die "cannot determine address";
	}
}
