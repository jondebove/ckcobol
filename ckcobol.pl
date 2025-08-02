#!/usr/bin/env perl
# ckcobol - check columns and GOTOs in Cobol source code
# Copyright 2011-2012 Jonathan Debove

use strict;
use warnings;

use Getopt::Std;
use Text::Tabs;

my $u = <<USAGE;
Usage:
      ckcobol [-h] [-t] [--] file1 [file2] ...

Options:
      -h  display this help
      -t  disable tab expansion
USAGE
my %o;
getopts('ht', \%o) or die $u;
$o{h} and die $u;
@ARGV or die "No argument given\n$u";
undef $u;

# COBOL conventions
my $f = qr{[A-Z0-9][A-Z0-9-]{0,28}[A-Z0-9]};
my @k = qw(
	END-IF END-EVALUATE END-READ END-WRITE END-DELETE END-REWRITE
	END-ACCEPT END-ADD END-SUBSTRACT END-MULTIPLY END-DIVIDE END-COMPUTE
	END-CALL END-PERFORM END-RETURN END-SEARCH END-START EXIT GOBACK
);

# Paragraph containers
my $b = '';  # Begin paragraph (after EXIT statement)
my $e = '';  # End paragraph (before EXIT statement)
my @g = ();  # GOTOs between Begin .. End paragraphs
my %p = ();  # Paragraphs between Begin .. End paragraphs

while (<>) {
	# Skip empty lines
	next if (/^\s*$/);

	# Expand tabs and unpack the columns 1-6,7,8-72,73-$
	my ($l, $c, $m, $r) = unpack "A6AA65A*", ($o{t} ? $_ : expand $_);

	# Check columns
	print "$ARGV: $.: non-empty left margin: `$l'\n" if ($l =~ /\S/);
	next if ($c eq '*' || $c eq '/');  # Skip comments
	print "$ARGV: $.: unknown indicator: `$c'\n" if ($c =~ /[^\sDd\$-]/);
	print "$ARGV: $.: non-empty right margin: `$r'\n" if ($r =~ /\S/);

	# Check GOTOs
	if ($m =~ /(?<![A-Z0-9-])GO\s+TO\s+($f)/i) {
		push @g, [ $., $1 ];
	}
	if ($m =~ /^\s{0,3}($f)(?=\.)/i) {
		next if (grep { uc($1) eq $_ } @k);
		$e = $1;
		$b ||= $e;
		$p{$e} = undef;
	}
	if ($m =~ /(?<![A-Z0-9-])EXIT(?=\.)/i) {
		for (grep { not exists $p{$$_[1]} } @g) {
			print "$ARGV: $$_[0]: goto `$$_[1]' in $b .. $e\n";
		}
		@g = %p = ();
		$b = $e = '';
	}
} continue {
	close ARGV if (eof ARGV);  # reset line count with multiple files
}
=head1 NAME

ckcobol - check columns and GOTOs in Cobol source code

=head1 SYNOPSIS

B<ckcobol> [B<-h>] [B<-t>] [B<-->] F<file1> [F<file2>] ...

=head1 DESCRIPTION

B<ckcobol> checks columns and GOTOs in the Cobol source files given as
argument. By default, the tabs are expanded with tabstop = 8.

=head1 OPTIONS

=over 8

=item B<-h>

display this help

=item B<-t>

disable tab expansion

=back

=head1 AUTHOR

Jonathan Debove
