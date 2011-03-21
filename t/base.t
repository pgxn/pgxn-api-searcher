#!/usr/bin/env perl -w

use strict;
use warnings;
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
    path
    searcher
);

# Build an index.
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
    my $dir = catdir qw(t _index);
    KinoSearch::Index::Indexer->new(
        index    => $dir,
        schema   => $schema,
        create   => 1,
    );
    END { remove_tree catdir $dir }
};

# Index some stuff.
