PGXN/API/Searcher
=================

This library's module, PGXN::API::Searcher, provides an interface to the
PGXN::API search engine index. You *must* have direct access to the index,
which is generated by PGXN::API. So if you use that module to create an API
server, you can use its index with this module. In fact, it uses *this* module
to serve the search API.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

PGXN-API-Searcher requires the following modules:

* perl 5.12.0
* Lucy 0.5.2

Copyright and License
---------------------

Copyright (c) 2011-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
