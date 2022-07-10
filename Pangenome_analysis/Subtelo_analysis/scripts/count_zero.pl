#!/usr/bin/env perl
use strict;

my $header = <>;

while(<>) {
	my ($og,@counts) = split;
	my $total = pop @counts;
	my $notzero = scalar grep { $_ != 0 } @counts;
	print join("\t", $og, $notzero >= 247 ? 'core' : 'accessory'),"\n";
}
