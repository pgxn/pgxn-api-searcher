use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'PGXN::API::Searcher',
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
        'Carp'       => 0,
        'File::Spec' => 0,
        'Lucy'       => '0.2.1',
        'perl'       => 5.010,
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/PGXN-API-Searcher/',
            bugtracker => 'http://github.com/pgxn/pgxn-api-searcher/issues/',
            repository => 'http://github.com/pgxn/pgxn-api-searcher/',
        }
    },
)->create_build_script;
