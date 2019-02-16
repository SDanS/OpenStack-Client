package OpenStack::Client::Utils;

use strict;
use warnings;
use JSON;
use Data::UUID;
use OpenStack::Client::Auth;

use Data::Dumper;

=pod 

=encoding utf8

=head1 NAME

OpenStack::Utils - A set of utility methods to accomplish common tasks on OpenStack utilizing OpenStack::Client

=head1 B<TODO:>

=over 2

=item E<0x2610> Need to get this in a system package installed into @INC. 

=item E<0x2610> Wire into QABot::cPBot and QABot::Config if necessary

=item E<0x2613> Pass the scope so that it is expressed to OpenStack::Auth::v3.

=back

=head1 DESCRIPTION

A set of utility methods to accomplish common tasks on OpenStack utilizing OpenStack::Client.

=head1 INSTANTIATION

=head2 C<OpenStack::Utils-E<gt>new()>

E<10>

=head3 B<Simple Use case>

E<10>

    my $auth = {
      'tenant' => $project_name,
      'username' => $username,
      'password' => $password,
    };
    my $request = {
      'method' => 'GET',
      'path' => '/servers/detail',
    };

    my $opts = {
      service => 'compute',
      auth_endpoint => $api_auth_url,
    };

=item B<Some callers or users may be admins.>

E<10>

    $request->{'body'} = {
      'all_tenants' => '1',
      'project_id' => 'bluedog@bigreddog.namedclifford.com',
    };    

=item B<Put your arguments together>

v3 authentification is preffered. It will be set later if 
not defined. I'd prefer not to say how to use v2.

E<10>

    my $opt = {
      'service' => 'compute',
      'auth_endpoint' => 'https://myauth.superfly.net:5001/',
    };

    $opts->{'auth'} = $auth;
    $opts->{'request'} = $request;

=item B<Boolean for creating reqest-ids to be tracked by OpenStack and the clients.>

=item

E<10>

    $opts->{'track_requests'} = 1;
    
=item B<Inital authentication and request.>

=item

E<10>

    my $os_util = OpenStack::Utils->new($opts);
    
=item B<Convenient additional requests.>

E<10>

    $os_util->request($request);

=item B<Passing a scope for auth.>

E<10>

    my $auth = { . . . }

    $auth->{'scope'} = {
      'project' => {
        'domain' => {
          'name' => "$domain_id",
        },
        'name' => %project_name
      },
    };
 
=item B<Array of json keys to filter on.>

E<10>

    $opts->{'response_filter'} = [ "OS-EXT-SRV-ATTR:hypervisor_hostname", "name" ];

=head2 Thoughts and future considerations:

=item * Domain scoping.

Do we have other domains defined besides default?
- Since the default domain is listed with each project in horizon:
  - We can project scope with project name and default domain.

=item * Authentication

Credentials currently supplied by caller. My recommendation is to 
create a separate credentials gathering utility for different callers. I didn't
want to tightly couple to anything here or in the modulino.


=cut

### Filter response
### Return JSON;

sub new {
    my ($class) = shift;
    my $opts    = shift;
    my $self    = {};
    bless $self, $class;
    $self->{'req_trace'} = $opts->{'track_requests'};
    $opts->{'auth'}->{'version'} //= 3;    # SSHHH!
    my $auth_endpoint = $opts->{'auth_endpoint'} . 
      "v" . $opts->{'auth'}->{'version'};
    $self->_set_os_cli(
        $opts->{'auth'},
        $opts->{'service'},
        $auth_endpoint
    );

    ### handle the inital request
    my $response = $self->request(
        $opts->{'request'},
        $opts->{'response_filter'}
    ) if $opts->{'request'};

    return $response, $self;
}

=head1 B<PUBLIC OBJECT INSTANCE METHODS>

=head2 Name: request

=head3 Usage: $os_cli-<gt>request($req);

=item B<Description>

=over 2

Build the request applying any global mutators.>
Send the request using OpenStack::Client::Auth::call().

=back

=cut

sub request {
    my $self   = shift;
    my $req    = shift;
    my $filter = shift;
    $req = $self->build_request($req) if $req;
    my $handle_response = sub {
      my $res = @_;
      print Dumper $res;
    };
    my $response = $self->{'os_cli'}->call($req, $handle_response);
    return $response;
    # return handle_response( $response, $filter );
}

=head2 Name: B<switch_os_cli>

=head3 Usage: C<$os_cli-<gt>switch_os_cli($new_service_name)

=item Switches the service used.

=over 2

Available services are in the auth response token-<gt>{'catalog'] which should be
stored in $os_cli-<gt>{'os_client'}-<gt>{'token'}-<gt>{'catalog'} and $os_clie-<gt>{'os_cli'}
-<gt>{'self'}-<gt>{'services'};

=back

=cut

sub switch_os_cli {
    my $self    = shift;
    my $new_svc = shift;
    $self->{'os_cli'} = $self->{'auth_response'}->service($new_svc);
    return $self;
}

=head1 B<PRIVATE OBJECT INSTANCE METHODS>

=head2 Name: B<_set_os_cli>

=head3 Usage: 

    $self->_set_os_cli(
        $opts->{'auth'},
        $opts->{'service'},
        $opts->{'auth_endpoint'}
    );

=item B<Description:>

=over 2 

Authenticates and returns the client specified in the $opts->{'service'}
argument hash and available in the $auth->{'tokens'}->{'catalog'}
returned from the authentication call.

=back

=cut

sub _set_os_cli {
    my $self         = shift;
    my $auth_params  = shift;
    my $service_args = shift;
    my $endpoint     = shift;
    ### Authenticate with $opts->{'auth'}
    $self->{'auth_response'} = OpenStack::Client::Auth->new(
        $endpoint,
        %$auth_params
    );
    ### Client object becomes a part of main object.
    $self->{'os_cli'} = $self->{'auth_response'}->service($service_args);
    return $self;
}

=head2 Method Name B<build_request>

=head3 Usage: C<$os_cli->build_request($req);

=item Description:

=over 2

A future proofing method to provide a place to mutate
or transform request parameters should the need arise.

Examples: 

Allow a coderef as an argument in order to 
inject some default behavior from a caller.

Blacklist certain methods or parameters.

.Or universally apply a parameter or header based
on some condition.

=back

=cut

sub build_request {
    my $self = shift;
    my $req  = shift;
    $req = $self->mutate_req($req);
    return $req;
}

# Apply request mutators.

sub mutate_req {
    my $self = shift;
    my $req  = shift;
    $req = request_trace($req) if $self->{'req_trace'};
    return $req;
}

=head1 B<Request Mutators>

Methods that transform requests 

=head2 Name:

request_trace()

Track requests in openstack with a request id.

=cut

sub request_trace {
    my $req    = shift;
    my $ug     = new Data::UUID;
    my $req_id = 'req-' . $ug->create_str();
    $req->{'headers'} = { 'X-Openstack-Request-Id' => $req_id };
    return $req;
}

# Select JSON Keys to return.

sub handle_response {
    my $res         = shift;
    my $response_ref = shift;
    ## my $filter_aref = shift;
    # print Dumper $filter_aref;
    print "I'M YOUR RESPONSE CHUNK!";
    print Dumper $res;
    print "I'M YOUR RESPONSE REF!";
    print Dumper $response_ref;
};

1;
