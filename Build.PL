use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'PGXN::API::Search',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30' },
    build_requires     => {
        'File::Path'            => '2.08',
        'File::Spec::Functions' => 0,
        'Module::Build'         => '0.30',
        'Test::More'            => '0.96',
    },
    requires => {
        'KinoSearch' => '0.311',
        'perl'       => 5.012,
    },
    recommends => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/PGXN-API-Search/',
            bugtracker => 'http://github.com/theory/pgxn-api-search/issues/',
            repository => 'http://github.com/theory/pgxn-api-search/tree/',
        }
    },
)->create_build_script;
