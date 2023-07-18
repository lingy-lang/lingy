use 5.006;
use strict;
use warnings;

package Bencode;
our $VERSION = '1.502';

use Exporter::Tidy all => [qw( bencode bdecode )];

our ( $DEBUG, $do_lenient_decode, $max_depth, $undef_encoding );

sub croak {
	my ( @c, $i );
	1 while ( @c = caller $i++ ) and $c[0] eq __PACKAGE__;
	@c or @c = caller;
	die @_, " at $c[1] line $c[2].\n";
}

sub _bdecode_string {

	if ( m/ \G ( 0 | [1-9] \d* ) : /xgc ) {
		my $len = $1;

		croak 'unexpected end of string data starting at ', 0+pos
			if $len > length() - pos();

		my $str = substr $_, pos(), $len;
		pos() = pos() + $len;

		warn "STRING (length $len)", $len < 200 ? " [$str]" : () if $DEBUG;

		return $str;
	}
	else {
		my $pos = pos();
		if ( m/ \G -? 0? \d+ : /xgc ) {
			pos() = $pos;
			croak 'malformed string length at ', 0+pos;
		}
	}

	return;
}

sub _bdecode_chunk {
	warn 'decoding at ', 0+pos if $DEBUG;

	local $max_depth = $max_depth - 1 if defined $max_depth;

	if ( defined( my $str = _bdecode_string() ) ) {
		return $str;
	}
	elsif ( m/ \G i /xgc ) {
		croak 'unexpected end of data at ', 0+pos if m/ \G \z /xgc;

		m/ \G ( 0 | -? [1-9] \d* ) e /xgc
			or croak 'malformed integer data at ', 0+pos;

		warn "INTEGER $1" if $DEBUG;
		return $1;
	}
	elsif ( m/ \G l /xgc ) {
		warn 'LIST' if $DEBUG;

		croak 'nesting depth exceeded at ', 0+pos
			if defined $max_depth and $max_depth < 0;

		my @list;
		until ( m/ \G e /xgc ) {
			warn 'list not terminated at ',0+pos,', looking for another element' if $DEBUG;
			push @list, _bdecode_chunk();
		}
		return \@list;
	}
	elsif ( m/ \G d /xgc ) {
		warn 'DICT' if $DEBUG;

		croak 'nesting depth exceeded at ', 0+pos
			if defined $max_depth and $max_depth < 0;

		my $last_key;
		my %hash;
		until ( m/ \G e /xgc ) {
			warn 'dict not terminated at ',0+pos,', looking for another pair' if $DEBUG;

			croak 'unexpected end of data at ', 0+pos
				if m/ \G \z /xgc;

			my $key = _bdecode_string();
			defined $key or croak 'dict key is not a string at ', 0+pos;

			croak 'duplicate dict key at ', 0+pos
				if exists $hash{ $key };

			croak 'dict key not in sort order at ', 0+pos
				if not( $do_lenient_decode ) and defined $last_key and $key lt $last_key;

			croak 'dict key is missing value at ', 0+pos
				if m/ \G e /xgc;

			$last_key = $key;
			$hash{ $key } = _bdecode_chunk();
		}
		return \%hash;
	}
	else {
		croak m/ \G \z /xgc ? 'unexpected end of data' : 'garbage', ' at ', 0+pos;
	}
}

sub bdecode {
	local $_ = shift;
	local $do_lenient_decode = shift;
	local $max_depth = shift;
	my $deserialised_data = _bdecode_chunk();
	croak 'trailing garbage at ', 0+pos if $_ !~ m/ \G \z /xgc;
	return $deserialised_data;
}

sub _bencode;
sub _bencode {
	map
	+( ( not defined     ) ? ( $undef_encoding or croak 'unhandled data type' )
	#:  ( not ref         ) ? ( m/\A (?: 0 | -? [1-9] \d* ) \z/x ? 'i' . $_ . 'e' : length . ':' . $_ )
	# TODO: This will treat all non-refs as strings, which might not be what we want.
	:  ( not ref ) ? length . ':' . $_
	:  ( 'SCALAR' eq ref ) ? ( length $$_ ) . ':' . $$_ # escape hatch -- use this to avoid num/str heuristics
	:  (  'ARRAY' eq ref ) ? 'l' . ( join '', _bencode @$_ ) . 'e'
	:  (   'HASH' eq ref ) ? 'd' . do { my @k = sort keys %$_; join '', map +( length $k[0] ) . ':' . ( shift @k ) . $_, _bencode @$_{ @k } } . 'e'
	:  croak 'unhandled data type'
	), @_
}

sub bencode {
	my $undef_mode = @_ == 2 ? pop : 'str';
	$undef_mode = 'str' unless defined $undef_mode;
	local $undef_encoding
		= 'str' eq $undef_mode ? '0:'
		: 'num' eq $undef_mode ? 'i0e'
		: 'die' eq $undef_mode ? undef
		: croak qq'undef_mode argument must be "str", "num", "die" or undefined, not "$undef_mode"';
	croak 'need exactly one or two arguments' if @_ != 1;
	( &_bencode )[0];
}

bdecode( 'i1e' );

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencode - BitTorrent serialisation format

=head1 SYNOPSIS

 use Bencode qw( bencode bdecode );

 my $bencoded = bencode { 'age' => 25, 'eyes' => 'blue' };
 print $bencoded, "\n";
 my $decoded = bdecode $bencoded;


=head1 DESCRIPTION

This module implements the BitTorrent I<bencode> serialisation format,
as described in L<http://www.bittorrent.org/beps/bep_0003.html#bencoding>.

=head1 INTERFACE

=head2 C<bencode( $datastructure [, $undef_mode ] )>

Takes data to be encoded as a single argument which may be a scalar,
or may be a reference to either
a scalar, an array or a hash. Arrays and hashes may in turn contain values of
these same types. Plain scalars that look like canonically represented integers
will be serialised as such. To bypass the heuristic and force serialisation as
a string, use a reference to a scalar.

The second argument is optional (in which case it defaults to C<str>) and
specifies how to treat C<undef> values. You can pick one of three options:

=over 6

=item C<str>

to encode C<undef>s as empty strings;

=item C<num>

to encode C<undef>s as zeroes;

=item C<die>

to croak upon encountering an C<undef> value.

=back

Croaks on unhandled data types.

=head2 C<bdecode( $string [, $do_lenient_decode [, $max_depth ] ] )>

Takes a string and returns the corresponding deserialised data structure.

If you pass a true value for the second option, it will disregard the sort
order of dict keys. This violation of the I<bencode> format is somewhat common.

If you pass an integer for the third option, it will croak when attempting to
parse dictionaries nested deeper than this level, to prevent DoS attacks using
maliciously crafted input.

Croaks on malformed data.

=head1 DIAGNOSTICS

=over

=item C<trailing garbage at %s>

Your data does not end after the first I<bencode>-serialised item.

You may also get this error if a malformed item follows.

=item C<garbage at %s>

Your data is malformed.

=item C<unexpected end of data at %s>

Your data is truncated.

=item C<unexpected end of string data starting at %s>

Your data includes a string declared to be longer than the available data.

=item C<malformed string length at %s>

Your data contained a string with negative length or a length with leading
zeroes.

=item C<malformed integer data at %s>

Your data contained something that was supposed to be an integer but didn't
make sense.

=item C<dict key not in sort order at %s>

Your data violates the I<bencode> format constaint that dict keys must appear
in lexical sort order.

=item C<duplicate dict key at %s>

Your data violates the I<bencode> format constaint that all dict keys must be
unique.

=item C<dict key is not a string at %s>

Your data violates the I<bencode> format constaint that all dict keys be
strings.

=item C<dict key is missing value at %s>

Your data contains a dictionary with an odd number of elements.

=item C<nesting depth exceeded at %s>

Your data contains dicts or lists that are nested deeper than the $max_depth
passed to C<bdecode()>.

=item C<unhandled data type>

You are trying to serialise a data structure that consists of data types other
than

=over

=item *

scalars

=item *

references to arrays

=item *

references to hashes

=item *

references to scalars

=back

The format does not support this.

=back

=head1 BUGS AND LIMITATIONS

Strings and numbers are practically indistinguishable in Perl, so C<bencode()>
has to resort to a heuristic to decide how to serialise a scalar. This cannot
be fixed.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
