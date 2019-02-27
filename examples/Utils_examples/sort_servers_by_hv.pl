#!/usr/bin/perl

use warnings;
use strict;
use FindBin;
use JSON;
use Term::ReadKey;

use Data::Dumper;

use lib qq{$FindBin::Bin/../todolib};

require( $FindBin::Bin . '/ocu_utility_modulino.pl' );


my $password = prompt_for_input('Enter your password: ');

my $scope_proj     = 'dan.stewart@cpanel.net';
my $username = 'admin';
my $cposcr_client = OpenStack::Client::Utils::Utility->new(
    'password' => $password,
    'username' => $username,
    'use_env_auth' => '1',
    'pw_in_tracking' => '1',
    'scope'    => {
        'type'        => 'project',
        'projectname' => $scope_proj,
    },
    'debug' => 1,
);

my $vmid_path    = [ 'servers', 'id' ];
my $hv_path      = [ 'servers', 'OS-EXT-SRV-ATTR:hypervisor_hostname' ];
my $vm_name_path = [ 'servers', 'name' ];

my $first_req_response_handler = {
    'subs' => [
        {
            'sub' => sub { $cposcr_client->value_concat(@_) },

            'args' => [
                $vmid_path, # [ 'servers', 'id' ]
                "/servers/<placeholder>"
            ]
        },

        #        {
        #            'sub' =>
        #        }
    ]

};

my %first_req_args = (
     'path' => '/servers',
);

my %request = (
    %first_req_args,
    'response_handler' => $first_req_response_handler
);

my $first_response = $cposcr_client->request( \%request );

#    my $json    = JSON->new();
#    my $hv_json = encode_json \@arr;
#    print $hv_json;

sub prompt_for_input {
    my $prompt_phrase = shift;
    my $echo          = shift;
    Term::ReadKey::ReadMode 'noecho' if !$echo;
    print $prompt_phrase;
    my $input = Term::ReadKey::ReadLine(0);
    Term::ReadKey::ReadMode('restore');
    print "\n";
    $input =~ s/\R\z//;
    return $input;
}

