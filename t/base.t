#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
#use Test::More tests => 50;
use Test::More 'no_plan';
use KinoSearch::Plan::Schema;
use KinoSearch::Plan::FullTextType;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Analysis::Tokenizer;
use KinoSearch::Index::Indexer;
use File::Spec::Functions qw(catdir);
use File::Path 'remove_tree';

my $CLASS;
BEGIN {
    $CLASS = 'PGXN::API::Search';
    use_ok $CLASS or die;
}

can_ok $CLASS => qw(
    new
    searcher
    parser
    search
);

# Build an index.
my $dir = catdir qw(t _index);
my $indexer = do {
    # Create the analyzer.
    my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new(
        language => 'en',
    );

    # Create the data types.
    my $fti = KinoSearch::Plan::FullTextType->new(
        analyzer      => $polyanalyzer,
        highlightable => 1,
    );

    my $string = KinoSearch::Plan::StringType->new(
        indexed => 1,
        stored  => 1,
    );

    my $indexed = KinoSearch::Plan::StringType->new(
        indexed => 1,
        stored  => 0,
    );

    my $stored = KinoSearch::Plan::StringType->new(
        indexed => 0,
        stored  => 1,
    );

    my $list  = KinoSearch::Plan::FullTextType->new(
        indexed       => 1,
        stored        => 1,
        boost         => 2.0,
        analyzer      => KinoSearch::Analysis::Tokenizer->new(pattern => '[^\003]'),
        highlightable => 1,
    );

    # Create the schema.
    my $schema = KinoSearch::Plan::Schema->new;
    $schema->spec_field( name => 'type',        type => $string  );
    $schema->spec_field( name => 'key',         type => $indexed );
    $schema->spec_field( name => 'title',       type => $fti     );
    $schema->spec_field( name => 'date',        type => $stored  );
    $schema->spec_field( name => 'username',    type => $fti     );
    $schema->spec_field( name => 'nickname',    type => $string  );
    $schema->spec_field( name => 'version',     type => $stored  );
    $schema->spec_field( name => 'abstract',    type => $fti     );
    $schema->spec_field( name => 'body',        type => $fti     );
    $schema->spec_field( name => 'tags',        type => $list    );
    $schema->spec_field( name => 'meta',        type => $fti     );
    $schema->spec_field( name => 'dist',        type => $stored  );
    $schema->spec_field( name => 'distversion', type => $stored  );

    # Create Indexer.
    KinoSearch::Index::Indexer->new(
        index    => $dir,
        schema   => $schema,
        create   => 1,
    );
    END { remove_tree catdir $dir }
};

# Index some stuff.
for my $doc (
    # Distribution "pair"
    {
        type     => 'dist',
        key      => 'pair',
        abstract => 'A key/value dåtå data type',
        body     => 'This library contains a single PostgreSQL extension, a key/value pair data type called `pair`, along with a convenience function for constructing key/value pairs.',
        date     => '2010-10-18T15:24:21Z',
        meta     => "postgresql license\nDavid E. Wheeler <david\@justatheory.com>\npair: A key/value pair data type",
        nickname => 'theory',
        tags     => "ordered pair\003pair",
        title    => 'pair',
        username => 'David E. Wheeler',
        version  => '0.1.0',
    },
    {
        type        => 'extension',
        key         => 'pair',
        abstract    => 'A key/value pair data type',
        body        => 'Doc for pair',
        date        => '2010-10-18T15:24:21Z',
        dist        => 'pair',
        distversion => '0.1.0',
        nickname    => 'theory',
        title       => 'pair',
        username    => 'David E. Wheeler',
        version     => '0.1.0',
    },
    {
        type     => 'user',
        key      => 'theory',
        meta     => "david\@justatheory.com\nhttp://justatheory.com/",
        nickname => 'theory',
        username => 'David E. Wheeler',
    },
    {
        type  => 'tag',
        key   => 'pair',
        title => 'pair',
    },
    {
        type  => 'tag',
        key   => 'key value',
        title => 'key value',
    },

    # Distribution "semver".
    {
        type     => 'dist',
        key      => 'semver',
        abstract => 'A semantic version data type',
        body     => 'Provides a data domain the enforces the Semantic Version format and includes support for operator-driven sort ordering.',
        date     => '2011-03-21T23:49:28Z',
        meta     => "mit license\nDuncan Wong <duncan\@wong.com>\npair: A semantic version data type\nperver: A less than semantic version data type (scary)",
        nickname => 'roger',
        tags     => "semver\003version\003semantic version",
        title    => 'semver',
        username => 'Roger Davidson',
        version  => '2.1.3',
    },
    {
        type        => 'extension',
        key         => 'semver',
        abstract    => 'A semantic version data type',
        body        => 'Loads of documentation for semver, you know how it is, what with taxes and all',
        date        => '2011-03-21T23:49:28Z',
        dist        => 'semver',
        distversion => '2.1.3',
        nickname    => 'roger',
        title       => 'semver',
        username    => 'Roger Davidson',
        version     => '1.3.4',
    },
    {
        type        => 'extension',
        key         => 'perver',
        abstract    => 'A less than semantic version data type (scary)',
        body        => 'Well, I got to thinking that while semver was useful, perver might be completely useless. So why not include it? And document it!',
        date        => '2011-03-21T23:49:28Z',
        dist        => 'semver',
        distversion => '2.1.3',
        nickname    => 'roger',
        title       => 'perver',
        username    => 'Roger Davidson',
        version     => '1.2.0',
    },
    {
        type     => 'user',
        key      => 'roger',
        meta     => "roger\@davidson.com\nhttp://rogerdavidson.com/",
        nickname => 'roger',
        username => 'Roger Davidson',
    },
    {
        type  => 'tag',
        key   => 'semver',
        title => 'semver',
    },
    {
        type  => 'tag',
        key   => 'version',
        title => 'version',
    },
    {
        type  => 'tag',
        key   => 'semantic version',
        title => 'semantic version',
    },
) {
    $indexer->add_doc($doc);
}

$indexer->commit;

# Okay, do some searches!
my $search = new_ok $CLASS, [$dir], 'Instance';
ok my $res = $search->search({query => 'ordered pair'}), 'Search for "ordered pair"';

