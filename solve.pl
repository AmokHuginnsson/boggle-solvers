#! /bin/sh
exec perl -w -x "${0}" "${@}"
#!perl
#line 5

use v5.28;
use feature qw(signatures);

use strict;
use warnings;

use Moops;
use MooseX::StrictConstructor;

use List::MoreUtils qw(uniq);

use Text::Trim qw(trim);

use Data::Dumper;

no warnings qw(experimental::signatures);

class DictionaryNode {
	has _finished => ( is => "rw", isa => Bool, default => 0 );
	has _next => ( is => "rw", isa => HashRef, default => sub{{}} );

	method add_suffix( Str $suffix_ ) {
		if ( length( $suffix_ ) == 0 ) {
			$self->_finished( 1 );
		} else {
			my $char = substr( $suffix_, 0, 1 );
			if ( ! exists( $self->_next->{$char} ) ) {
				$self->_next->{$char} = DictionaryNode->new();
			}
			$self->_next->{$char}->add_suffix( substr( $suffix_, 1 ) );
		}
	}

	method get( Str $char_ ) {
		my $result = undef;
		if ( exists( $self->_next->{$char_} ) ) {
			$result = $self->_next->{$char_};
		}
		return ( $result );
	}

	method print_all( Str $prefix_ = "" ) {
		if ( $self->_finished ) {
			print( $prefix_ . "\n" );
		}
		foreach my $char ( keys( $self->_next->%* ) ) {
			$self->_next->{$char}->print_all( $prefix_ . $char );
		}
	}
}

class Cube {
	has _letter => ( is => "rw", isa => Str, default => undef );
	has _visited => ( is => "rw", isa => Bool, default => 0 );
	has _neighbors => ( is => "rw", isa => ArrayRef, default => sub{[]} );
	method BUILDARGS( ClassName $class: Str $letter_ ) {
		return ( $class->SUPER::BUILDARGS( _letter => $letter_ ) );
	}
}

class Board {
	has _cubes => ( is => "rw", isa => ArrayRef, default => sub{[]} );
	has _size => ( is => "rw", isa => Int, default => 0 );
	has _letters => ( is => "rwp", isa => Str, required => 1 );
	method BUILDARGS( ClassName $class: Str $letters_ ) {
		return ( $class->SUPER::BUILDARGS( _letters => $letters_ ) );
	}
	method BUILD( $ ) {
		my $len = sqrt( length( $self->_letters ) );
		assert( $len * $len == length( $self->_letters ) );
		$self->_size( $len );
		foreach my $l ( split( "", $self->_letters ) ) {
			push( $self->_cubes->@*, Cube->new( $l ) );
		}
		my @deltas = ([-1,-1], [-1,0], [-1,1], [0,-1], [0,1], [1,-1], [1,0], [1,1]);
		foreach my $x ( 0 .. $len - 1 ) {
			foreach my $y ( 0 .. $len - 1 ) {
				foreach my $d ( @deltas ) {
					my $nx = $x + $d->[0];
					my $ny = $y + $d->[1];
					if ( ( $nx >= 0 ) && ( $nx < $len ) && ( $ny >= 0 ) && ( $ny < $len ) ) {
						push( @{$self->get_cube( $x, $y )->_neighbors}, $self->get_cube( $nx, $ny ) );
					}
				}
			}
		}
	}

	method get_cube( Int $x_, Int $y_ ) {
		return ( $self->_cubes->[$y_ * $self->_size + $x_] );
	}

	method solve( $dictionary_ ) {
		my @result = ();
		foreach my $cube ( @{$self->_cubes()} ) {
			$self->solve_recursive( \@result, "", $cube, $dictionary_ );
		}
		return ( ::uniq( sort( { length( $a ) <=> length( $b ) } @result ) ) );
	}

	method solve_recursive( $result, Str $prefix_, $cube_, $dictNode_ ) {
		my $nextNode = $dictNode_->get( $cube_->_letter() );
		if ( $nextNode == undef ) {
			return;
		}
		$cube_->_visited( 1 );
		my $newPrefix = $prefix_ . $cube_->_letter;
		if ( $nextNode->_finished && ( length( $newPrefix ) >= 3 ) ) {
			push( @{$result}, $newPrefix );
		}
		foreach my $neighbor ( @{$cube_->_neighbors} ) {
			if ( ! $neighbor->_visited ) {
				$self->solve_recursive( $result, $newPrefix, $neighbor, $nextNode );
			}
		}
		$cube_->_visited( 0 );
	}
}

sub main( @argv_ ) {
	my $dictionaryRoot = DictionaryNode->new();
	open( my $dictFile, "<", $argv_[1] );
	while ( my $line = <$dictFile> ) {
		$dictionaryRoot->add_suffix( trim( $line ) );
	}
	close( $dictFile );
#	$dictionaryRoot->print_all();
	print( "[ OK ] Ready\n" );
	my $letters = "";
	LOOP: while ( 1 ) {
		my $line = <STDIN>;
		if ( ! $line ) {
			last LOOP;
		}
		$line = trim( $line );
		if ( ( length( $letters ) > 0 ) && ( length( $line ) == 0 ) ) {
			print( "[ OK ] Solving\n" );
			my $board = Board->new( $letters );
			foreach my $word ( $board->solve( $dictionaryRoot ) ) {
				print( "(" . length( $word ) . ") " . $word . "\n" );
			}
			print( "[ OK ] Solved\n" );
			$letters = "";
		} else {
			$letters = $letters . $line;
		}
	}
	return ( 0 );
}

main( (($0), @ARGV ) );

# vim: set ft=perl:
