package PGXN::API::Searcher v0.5.6;

use 5.12.0;
use utf8;
use File::Spec;
use KinoSearch::Search::IndexSearcher;
use KinoSearch::Search::QueryParser;
use KinoSearch::Highlight::Highlighter;
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
    doc       => [qw(title abstract dist version path date user user_name)],
    dist      => [qw(dist version abstract date user user_name)],
    extension => [qw(extension abstract dist version date user user_name)],
    user      => [qw(user name uri)],
    tag       => [qw(tag)],
);

sub search {
    my ($self, $iname, $params) = @_;
    my $searcher = $self->{searchers}{$iname} or croak "No $iname index";
    my $query    = $self->{parsers}{$iname}->parse($params->{query});
    my $limit    = ($params->{limit} ||= 50) < 1024 ? $params->{limit} : 50;

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
            return excerpt => $h->create_excerpt(shift);
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

PGXN::API::Searcher - PGXN API full text search interface

=head1 Synopsis

  use PGXN::API::Searcher;
  use JSON;
  my $search = PGXN::API::Searcher->new('/path/to/index');
  encode_json $search->search(doc => { query => $query });

=head1 Description

This module encapsulates the PGXN API search functionality. The indexes are
created by L<PGXN::API::Indexer>; this module parses search queries, executes
them against the appropriate index, and returns the results as a hash suitable
for serializing to L<JSON|http://json.org> for a response to a request.

To use this module, one must have a path to the search indexes created by
PGXN::API. That is, with access to the same file system. It is therefore use
by PGXN::API itself to process search requests. It can also be used by
WWW::PGXN if its mirror URI is specified as a C<file:> URI.

Unless you're creating a PGXN API of your own, or accessing one via the local
file system (as L<PGXN::Site> does via L<WWW::PGXN>), you probably don't need
this module. Best to just use L<WWW::PGXN>.

But in case you I<do> want to use this module, here are the gory details.

=head1 Interface

=head2 Constructor

=head3 C<new>

  my $search = PGXN::API::Searcher->new('/path/to/pgxn/index');

Constructs a PGXN::API::Searcher object, pointing it to a valid PGXN::API full
text search index path.

=head2 Accessors

=head3 C<searchers>

  my $doc_searcher = $search->searchers->{doc};

Returns a hash reference of index search objects. The keys are the names of
the indexes, and the values are L<KinoSearch::Search::IndexSearcher> objects.

=head3 C<parsers>

  my $doc_parser = $search->parsers->{doc};

Returns a hash reference of search query parsers. The keys are the names of
the indexes, and the values are L<KinoSearch::Search::QueryParser> objects.

=head2 Instance Method

=head3 C<search>

  my $results = $search->search( doc => { query => $q });

Queries the search index and returns a hash reference with the results. The
first argument specifies the index to query. The possible values are covered
below. The parameters supported in the hash reference second argument are:

=over

=item query

The search query. See L<KinoSearch::Search::QueryParser> for the supported
syntax of the query. Required.

=item offset

How many hits to skip before showing results. Defaults to 0.

=item limit

Maximum number of hits to return. Defaults to 50 and may not be greater than
1024.

=back

The results will be returned as a hash with the following keys:

=over

=item query

The query string. Same value as the C<query> parameter.

=item limit

Maximum number of records returned. Same as the C<limit> parameter unless it
exceeds 1024, in which case it will be the default value, 50.

=item offset

The number of hits skipped.

=item count

The total count of hits, without regard to C<limit> or C<offset>. Use for
laying out pagination links.

=item hits

An array of hash references. These constitute the search results. The keys in
the hashes depend on which index was searched. See below for that information.

=back

The first argument must be the name of the index. The possible values are:

=over

=item doc

Full text indexing of PGXN documentation. The C<hits> hashes will have the
following keys:

=over

=item title

The document title.

=item abstract

The document abstract.

=item excerpt

An excerpt from the document with the search keywords highlighted in C<
<<strong>> > tags.

=item dist

The name of the distribution in which the document is found.

=item version

The version of the distribution in which the document is found.

=item path

The path to the document within the distribution.

=item date

The distribution date.

=item user

The nickname of the user who created the distribution.

=item user_name

The full name of the user who created the distribution.

=back

=item dist

Full text search of PGXN distributions. The C<hits> hashes will have the
following keys:

=over

=item name

The name of the distribution.

=item version

The distribution version.

=item excerpt

An excerpt from the distribution with the search keywords highlighted in C<
<<strong>> > tags.

=item abstract

The distribution abstract.

=item date

The distribution date.

=item user

The nickname of the user who created the distribution.

=item user_name

The full name of the user who created the distribution.

=back

=item extension

Full text search of PGXN extensions. The C<hits> hashes will have the following
keys:

=over

=item name

The name of the extension.

=item excerpt

An excerpt from the extension with the search keywords highlighted in C<
<<strong>> > tags.

=item abstract

The extension abstract.

=item dist

The name of the distribution in which the extension is found.

=item version

The version of the distribution in which the extension is found.

=item date

The distribution date.

=item user

The nickname of the user who created the distribution.

=item user_name

The full name of the user who created the distribution.

=back

=item user

Full text search of PGXN users. The C<hits> hashes will have the following
keys:

=over

=item user

The user's nickname.

=item name

The user's full name.

=item uri

The user's URI

=item excerpt

An excerpt from the user with the search keywords highlighted in
 C< <<strong>> > tags.

=back

=item tag

Full text search of PGXN tags. The C<hits> hashes will have the following keys:

=over

=item name

The tag name.

=back

=back

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
