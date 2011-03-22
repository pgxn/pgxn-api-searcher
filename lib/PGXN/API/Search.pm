package PGXN::API::Search v0.5.6;

use 5.12.0;
use utf8;
use File::Spec;
use Carp;

sub new {
    my ($class, $path) = @_;
    my (%searchers, %parsers);
    for my $iname (qw(doc dist extension user tag)) {
        $searchers{$iname} = KinoSearch::Search::IndexSearcher->new(
            index => File::Spec->catdir($path, $iname)
        );
        $parsers{$iname} = KinoSearch::Search::QueryParser->new(
            schema => $searchers{$iname}->get_schema
        )
    }
    bless {
        searchers => \%searchers,
        parsers   => \%parsers,
    } => $class;
}

sub searchers { shift->{searchers} }
sub parsers { shift->{parsers} }

my %highlightable = (
    doc       => 'body',
    dist      => 'readme',
    extension => 'abstract',
    user      => 'details',
    tag       => undef,
);

my %fields = (
    doc       => [qw(title abstract dist version date nickname username)],
    dist      => [qw(name version abstract date nickname username)],
    extension => [qw(name abstract dist version date nickname username)],
    user      => [qw(nickname name uri)],
    tag       => [qw(name)],
);

sub search {
    my ($self, $iname, $params) = @_;
    my $searcher = $self->{searchers}{$iname} or croak "No $iname index";
    my $query    = $self->{parsers}{$iname}->parse($params->{query});
    my $limit    = ($params->{limit} ||= 50) < 1000 ? $params->{limit} : 50;

    my $hits = $searcher->hits(
        query      => $query,
        offset     => $params->{offset},
        num_wanted => $limit,
    );

    # Arrange for highlighted excerpts to be created.
    my $highlighter;
    if (my $field = $highlightable{$iname}) {
        my $h = KinoSearch::Highlight::Highlighter->new(
            searcher => $searcher,
            query    => $params->{query},
            field    => $field,
        );
        $highlighter = sub {
            return (excerpt => $h->create_excerpt(shift));
        };
    } else {
        $highlighter = sub { };
    }

    my %ret = (
        query  => $params->{query},
        offset => $params->{offset} || 0,
        limit  => $limit,
        count  => $hits->total_hits,
        hits   => my $res = [],
    );

    # Create result list.
    while ( my $hit = $hits->next ) {
        push @{ $res } => {
            score    => sprintf( "%0.3f", $hit->get_score ),
            $highlighter->($hit),
            map { $_ => $hit->{$_} } @{ $fields{$iname} }
        };
    }

    return \%ret;
}

1;

__END__

=head1 Name

PGXN::API::Search - PGXN API full text search interface

=head1 Synopsis

  use PGXN::API::Search;
  use JSON;
  my $search PGXN::API::Search->new({
      path => '/path/to/index',
  });

  encode_json $search->search( query => $query );

=head1 Description

More to come.

=head3 C<search>

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut
