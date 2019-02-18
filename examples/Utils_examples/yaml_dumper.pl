use YAML::Tiny;

=pod

=head1 I can store requests any way I want now!

=head2 look, why wouldn't we store it in yaml?!

=cut

my $scope_templates = {
    'system' => {
        'scope' => {
            'system' => { "all" => 'true' },
        },
    },
    'project' => {
        'scope' => {
            'project' => {
                'domain' => { 'name' => 'default' },
                'name'   => '<project_name>'
            }
        }
    }
};

my $auth_tmpl = {
    'token_request' => {
        'request_body' => {
        'auth' => {
            'identity' => {
                'methods' => ['token'],
                'token'   => { 'id' => '<toke>' }
            }
        }
        }
    },
    'passwd_request' => {
        'request_body' => {
        'auth' => {
            'identity' => {
                'methods'  => ['password'],
                'password' => {
                    'user' => {
                        'name'     => '<username>',
                        'password' => '<password>',
                        'domain'   => { 'name' => 'default' }
                    }
                }
            }
        }
        }
    }
};

my $auth = {
    # Currently expressed in example/Utils_examples/subclass_libs/Intercept.pm
    # 'endpoint'     => 'https://bigreddog.namedclifford.com:5001/',
    'request_body' => {
        'auth' => {
            'identity' => {
                'methods'  => ['password'],
                'password' => {
                    'user' => {
                        'name'     => 'admin',
                        'password' => 'imanadmin',
                        'domain'   => { 'name' => 'default' }
                    }
                }
            }
        }
    }
};

my $req_arr = [];
my $req_arr->[0] = {
    ### 'label' is just for my own use to describe the call in debug.
    'label'   => 'hypervisor-server-search-<someproject>',
    'service' => 'compute',
    'method'  => 'GET',
    'path'    => '/servers/detail',
    'request_body' => {
    'auth'    => {
        'scope' => {
            'project' => {
                'name'   => 'someproject',
                'domain' => { 'name' => 'default' },
            },
        },
        },
    },
    'body' => {
        'all_tenants' => '1',
        'project_id'  => 'someproject',
    },
    'response_filter' => [
        "name",
        "OS-EXT-SRV-ATTR:hypervisor_hostname",
        "image",
    ]
};

$req_arr->[1] = {
    # For tracking.
    'label'   => 'resource_providers',
    'service' => 'placement',
    'method'  => 'GET',
    'path'    => '/resource_providers',
    'request_body' => {
    'auth'    => {
        'scope' => {
            'system' => { "all" => "true" },
        },
    },
    },
};

my $yaml_auth     = YAML::Tiny->new($auth);
my $yaml_requests = YAML::Tiny->new();
foreach (@$req_arr) {
    push @$yaml_requests, $_;
}

$yaml_auth->write('./os_auth.yml');
$yaml_requests->write('./os_requests.yml');
