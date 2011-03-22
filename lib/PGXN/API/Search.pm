package PGXN::API::Search v0.5.6;

use 5.12.0;
use utf8;
use Moose;

sub new {
    my ($class, $path) = @_;
    my $searcher = KinoSearch::Search::IndexSearcher->new(index => $path);
    bless {
        searcher => $searcher,
        parser   => KinoSearch::Search::QueryParser->new(
            schema => $searcher->get_schema
        ),
    } => $class;
}

sub searcher { shift->{searcher} }
sub parser { shift->{parser} }

my %fields = (
    dist      => [qw(title version abstract date nickname username)],
    extension => [qw(title version abstract date nickname username dist distversion)],
    tag       => [qw(title)],
    user      => [qw(nickname username)],
);

sub search {
    my ($self, $params) = @_;
    my $query = $self->parser->parse($params->{query});
    if (my $type = $params->{type}) {
        my $type_query = KinoSearch::Search::TermQuery->new(
            field => 'type',
            term  => $type,
        );
        $query = KinoSearch::Search::ANDQuery->new(
            children => [ $query, $type_query ]
        );
    }

    my $hits = $self->searcher->hits(
        query      => $query,
        offset     => $params->{offset},
        num_wanted => $params->{limit},
    );

    # Arrange for highlighted excerpts to be created.
    my $highlighter = KinoSearch::Highlight::Highlighter->new(
        searcher => $self->searcher,
        query    => $params->{query},
        field    => 'body'
    );

    my %ret = (
        type   => $params->{type},
        query  => $params->{query},
        offset => $params->{offset} || 0,
        limit  => $params->{limit},
        count  => $hits->total_hits,
        hits   => my $res = [],
    );

    # Create result list.
    while ( my $hit = $hits->next ) {
        push @{ $res } => {
            score    => sprintf( "%0.3f", $hit->get_score ),
            type     => $hit->{type},
            excerpt  => $highlighter->create_excerpt($hit),
            map { $_ => $hit->{$_} } @{ $fields{ $hit->{type} } }
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
