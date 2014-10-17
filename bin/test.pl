#!/usr/bin/perl -w
use strict;
use lib '.';
use Flutterby::Parse::FullyEscapedString;
use Data::Dumper;

my $p = Flutterby::Parse::FullyEscapedString->new();
print Dumper($p->parse('Some &#147; text &#148; stuff '));

