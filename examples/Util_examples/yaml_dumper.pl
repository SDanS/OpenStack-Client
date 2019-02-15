use YAML::Tiny;


=pod

=head1 I can store requests any way I want now!

=head2 look, why wouldn't we store it in yaml?!

=cut

my $auth = {
    'tenant' => 'admin',
    'username' => 'admin',
    'password' => "i\'manadmin!",
};

$auth->{'scope'} ={
    'project' => {
        'name' => 'admin',
        'domain' => {
            'name' => 'default'
        },
    },
};

my $request = {
    'method' => 'GET',
    'path' => '/servers/detail'
};

$request->{'body'} = {
    'all_tenants' => '1',
    'project_id' => 'bluedog@bigreddog.namedclifford.com',
};

my $opts = {
    'service' => 'compute',
    'auth_endpoint' => 'https://bigreddog.namedclifford.net:5001/',
    'response_filter' => [
        "OS-EXT-SRV-ATTR:hypervisor_hostname",
        "name"
    ]
};

$opts->{'request'} = $request;

my $yaml_auth = YAML::Tiny->new($auth);
my $yaml_opts = YAML::Tiny->new($opts);

$yaml_auth->write('./os_auth.yml');
$yaml_opts->write('./os_opts.yml');
