#!/usr/bin/perl

package poc_scripts::get_server_hv;

use warnings;
use strict;
use FindBin;
use JSON;
use YAML::Tiny;

use Data::Dumper;

use OpenStack::Client::Utils;

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
    my $opts = fetch_request_data();
    $opts->{'auth'} = fetch_auth_data();
    my ($response, $os_util) = OpenStack::Client::Utils->new($opts);
    print Dumper $response;
}

sub fetch_request_data {
    my $opts_yaml = YAML::Tiny->read('/Users/dan/os_opts.yml');
    my $opts = $opts_yaml->[0];
    return $opts;
}

sub fetch_auth_data {
    my $auth_yaml = YAML::Tiny->read('/Users/dan/os_auth.yml');
    my $auth = $auth_yaml->[0];
    return $auth;
}
