#!/usr/bin/perl

package poc_scripts::get_server_hv;

use warnings;
use strict;
use FindBin;
use JSON;
use YAML::Tiny;
use FindBin;

use Data::Dumper;

use lib qq{$FindBin::Bin/subclass-libs/};

use Intercept;

exit(main(@ARGV)) unless caller;

=pod

=head1 Name:

get_server_hv.pl

=head1 Description:

A quick script which utilizes OpenStack::Utils and OpenStack::Client to retrive
all instances filtered on project.

This script demonstrates how to use OpenStack::Utils to easily make API
requests.

=head1 TODO:

=over 2

=item E<0x2610>

Read credentials from local file for now.

=item E<0x2610>

Improve the modulino pattern.

=item E<0x2610>

Read request methods from file.

=back

=head2 main()

The main logic of the script.

=cut

sub main {
    my $requests = fetch_request_data();
    my $auth = fetch_auth_data();
    my $os_util = OpenStack::Client::Utils::Intercept->new($auth);
    my $response_collection = [];
    foreach my $request (@$requests) {
        push @$response_collection, $os_util->request($request);
    }
    ### Do work with the response_colection.
}

sub fetch_request_data {
    my $requests_yaml = YAML::Tiny->read('/Users/dan/os_requests.yml');
    my $requests = $requests_yaml;
    return $requests;
}

sub fetch_auth_data {
    my $auth_yaml = YAML::Tiny->read('/Users/dan/os_auth.yml');
    my $auth = $auth_yaml->[0];
    return $auth;
}
