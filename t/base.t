#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 23;
#use Test::More 'no_plan';
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
    searchers
    parsers
    search
);

# Build an index.
my $dir = catdir qw(t _index);
my %indexers;

INDEX: {
    if (!-e $dir) {
        require File::Path;
        File::Path::make_path($dir);
    }

    my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new(
        language => 'en',
    );

    my $fti = KinoSearch::Plan::FullTextType->new(
        analyzer      => $polyanalyzer,
        highlightable => 0,
    );

    my $ftih = KinoSearch::Plan::FullTextType->new(
        analyzer      => $polyanalyzer,
        highlightable => 1,
    );

    my $indexed = KinoSearch::Plan::StringType->new(
        indexed => 1,
        stored  => 0,
    );

    my $stored = KinoSearch::Plan::StringType->new(
        indexed => 0,
        stored  => 1,
    );

    my $list = KinoSearch::Plan::FullTextType->new(
        indexed       => 1,
        stored        => 1,
        highlightable => 1,
        analyzer      => KinoSearch::Analysis::Tokenizer->new(
            pattern => '[^\003]'
        ),
    );

    for my $spec (
        [ doc => [
            [ key         => $indexed ],
            [ title       => $fti     ],
            [ abstract    => $fti     ],
            [ body        => $ftih    ],
            [ dist        => $fti     ],
            [ version     => $stored  ],
            [ date        => $stored  ],
            [ username    => $stored  ],
            [ nickname    => $stored  ],
        ]],
        [ dist => [
            [ key         => $indexed ],
            [ name        => $fti     ],
            [ abstract    => $fti     ],
            [ description => $fti     ],
            [ readme      => $ftih    ],
            [ tags        => $list    ],
            [ version     => $stored  ],
            [ date        => $stored  ],
            [ username    => $stored  ],
            [ nickname    => $stored  ],
        ]],
        [ extension => [
            [ key         => $indexed ],
            [ name        => $fti     ],
            [ abstract    => $ftih    ],
            [ dist        => $stored  ],
            [ version     => $stored  ],
            [ date        => $stored  ],
            [ username    => $stored  ],
            [ nickname    => $stored  ],
        ]],
        [ user => [
            [ key         => $indexed ],
            [ nickname    => $fti     ],
            [ name        => $fti     ],
            [ email       => $indexed ],
            [ uri         => $indexed ],
            [ details     => $ftih    ],
        ]],
        [ tag => [
            [ key         => $indexed ],
            [ name        => $fti     ],
        ]],
    ) {
        my ($name, $fields) = @{ $spec };
        my $schema = KinoSearch::Plan::Schema->new;
        $schema->spec_field(name => $_->[0], type => $_->[1] )
            for @{ $fields };
        $indexers{$name} = KinoSearch::Index::Indexer->new(
            index    => catdir($dir, $name),
            schema   => $schema,
            create   => 1,
        );
    }
    END { remove_tree catdir $dir }
}

# Index some stuff.
for my $doc (
    # Distribution "pair"
    {
        type        => 'dist',
        abstract    => 'A key/value pair data type',
        date        => '2010-10-18T15:24:21Z',
        description => "This library contains a single PostgreSQL extension, a key/value pair data type called `pair`, along with a convenience function for constructing key/value pairs.",
        key         => 'pair',
        name        => 'pair',
        nickname    => 'theory',
        readme      => 'This is the pair README file. Here you will find all thingds related to pair, including installation information',
        tags        => "ordered pair\003pair",
        username    => 'David E. Wheeler',
        version     => '0.1.0',
    },
    {
        type     => 'extension',
        abstract => 'A key/value pair data type',
        date     => '2010-10-18T15:24:21Z',
        dist     => 'pair',
        key      => 'pair',
        name     => 'pair',
        nickname => 'theory',
        username => 'David E. Wheeler',
        version  => '0.1.0',
    },
    {
        type     => 'user',
        details  => "theory\nDavid has a bio, yo. Perl and SQL and stuff",
        email    => 'david@example.com',
        key      => 'theory',
        name     => 'David E. Wheeler',
        nickname => 'theory',
        uri      => 'http://justatheory.com/',
    },
    {
        type => 'tag',
        key  => 'pair',
        name => 'pair',
    },
    {
        type => 'tag',
        key  => 'key value',
        name => 'key value',
    },
    {
        type     => 'doc',
        abstract => 'A key/value pair data type',
        body     => 'The ordered pair data type is nifty, I tell ya!',
        date     => '2010-10-18T15:24:21Z',
        dist     => 'pair',
        key      => 'pair/doc/pair',
        nickname => 'theory',
        title    => 'pair 0.1.0',
        username => 'David E. Wheeler',
        version  => '0.1.0',
    },

    # Distribution "semver".
    {
        type        => 'dist',
        abstract    => 'A semantic version data type',
        date        => '2010-10-18T15:24:21Z',
        description => 'Provides a data domain the enforces the Semantic Version format and includes support for operator-driven sort ordering.',
        key         => 'semver',
        name        => 'semver',
        nickname    => 'roger',
        readme      => "README for the semver distribion. Installation instructions\n",,
        tags        => "semver\003version\003semantic version",
        username    => 'Roger Davidson',
        version     => '2.1.3',
    },
    {
        type     => 'extension',
        abstract => 'A semantic version data type',
        date     => '2011-03-21T23:49:28Z',
        dist     => 'semver',
        key      => 'semver',
        name     => 'semver',
        nickname => 'roger',
        username => 'Roger Davidson',
        version  => '1.3.4',
    },
    {
        type     => 'extension',
        abstract => 'A less than semantic version data type (scary)',
        date     => '2011-03-21T23:49:28Z',
        dist     => 'semver',
        key      => 'perver',
        name     => 'perver',
        nickname => 'roger',
        username => 'Roger Davidson',
        version  => '1.3.4',
    },
    {
        type     => 'user',
        details  => "roger\nRoger is a Davidson. Har har.",
        email    => 'roger@example.com',
        key      => 'roger',
        name     => 'Roger Davidson',
        nickname => 'roger',
        uri      => 'http://roger.example.com/',
    },
    {
        type => 'tag',
        key  => 'semver',
        name => 'semver',
    },
    {
        type => 'tag',
        key  => 'version',
        name => 'version',
    },
    {
        type => 'tag',
        key  => 'semantic version',
        name => 'semantic version',
    },
) {
    my $indexer = $indexers{delete $doc->{type}};
    $indexer->add_doc($doc);
}

$_->commit for values %indexers;

# Okay, do some searches!
my $search = new_ok $CLASS, [$dir], 'Instance';
ok my $res = $search->search(dist => {query => 'ordered pair'}),
    'Search docs for "ordered pair"';
is_deeply $res, {
    query  => "ordered pair",
    limit  => 50,
    offset => 0,
    count  => 2,
    hits   => [
        {
            abstract => "A key/value pair data type",
            date     => "2010-10-18T15:24:21Z",
            excerpt  => "This is the <strong>pair</strong> README file. Here you will find all thingds related to <strong>pair</strong>, including installation information",
            name     => "pair",
            nickname => "theory",
            score    => "1.251",
            username => "David E. Wheeler",
            version  => "0.1.0",
        },
        {
            abstract => "A semantic version data type",
            date     => "2010-10-18T15:24:21Z",
            excerpt  => "README for the semver distribion. Installation instructions",
            name     => "semver",
            nickname => "roger",
            score    => "0.008",
            username => "Roger Davidson",
            version  => "2.1.3",
        },
    ],
}, 'Should have results for simple search';

# Test offset.
ok $res = $search->search(dist => {
    query => 'ordered pair',
    offset => 1,
}), 'Search with offset';
is $res->{count}, 2, 'Count should be 2';
is @{ $res->{hits} }, 1, 'Should have one hit';
is $res->{hits}[0]{name}, 'semver', 'It should be the second record';

# Try limit.
ok $res = $search->search(dist => {
    query => 'ordered pair',
    limit => 1,
}), 'Search with limit';
is $res->{count}, 2, 'Count should again be 2';
is @{ $res->{hits} }, 1, 'Should again have one hit';
is $res->{hits}[0]{name}, 'pair', 'It should be the first record';

# Exceed the limit.
ok $res = $search->search(dist => {
    query => 'ordered pair',
    limit => 1024,
}), 'Search with excessive limit';
is $res->{limit}, 50, 'Excessive limit should be ignored';

# Search for other stuff.
ok $res = $search->search(doc => { query => 'nifty'}),
    'Seach the docs';
is_deeply $res, {
    query  => "nifty",
    limit  => 50,
    offset => 0,
    count  => 1,
    hits   => [
        {
            abstract => "A key/value pair data type",
            date     => "2010-10-18T15:24:21Z",
            dist     => "pair",
            excerpt  => "The ordered pair data type is <strong>nifty</strong>, I tell ya!",
            nickname => "theory",
            score    => "0.015",
            title    => "pair 0.1.0",
            username => "David E. Wheeler",
            version  => "0.1.0",
        },
    ],
}, 'Should have expected structure for docs';

ok $res = $search->search(extension => { query => 'semantic'}),
    'Seach extensions';
is_deeply $res, {
    query  => "semantic",
    limit  => 50,
    offset => 0,
    count  => 2,
    hits   => [
        {
            abstract => "A semantic version data type",
            date     => "2011-03-21T23:49:28Z",
            dist     => "semver",
            excerpt  => "A <strong>semantic</strong> version data type",
            name     => "semver",
            nickname => "roger",
            score    => "0.140",
            username => "Roger Davidson",
            version  => "1.3.4",
        },
        {
            abstract => "A less than semantic version data type (scary)",
            date     => "2011-03-21T23:49:28Z",
            dist     => "semver",
            excerpt  => "A less than <strong>semantic</strong> version data type (scary)",
            name     => "perver",
            nickname => "roger",
            score    => "0.100",
            username => "Roger Davidson",
            version  => "1.3.4",
                },
    ],
}, 'Should have expected structure for extensions';


ok $res = $search->search(user => { query => 'Davidson'}), 'Seach users';
is_deeply $res, {
    query  => "Davidson",
    limit  => 50,
    offset => 0,
    count  => 1,
    hits   => [
        {
            excerpt => "roger\nRoger is a <strong>Davidson</strong>. Har har.",
            name => "Roger Davidson",
            nickname => "roger",
            score => "0.272",
            uri => undef,
        },
    ],
}, 'Should have expected structure for users';

ok $res = $search->search(tag => { query => 'version'}), 'Seach tags';
is_deeply $res, {
    query  => "version",
    limit  => 50,
    offset => 0,
    count  => 2,
    hits   => [
        { name => "version", score => "2.440" },
        { name => "semantic version", score => "0.292" },
    ],
}, 'Should have expected structure for tags';
