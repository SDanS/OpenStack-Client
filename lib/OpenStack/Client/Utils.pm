package OpenStack::Client::Utils;

use strict;
use warnings;
use JSON;
use Data::UUID;
use OpenStack::Client::Auth;
use Scalar::Util;

use strict;
use warnings;

=pod 

=encoding utf8

=head1 NAME

OpenStack::Client::Utils - A set of utility methods to accomplish common tasks on OpenStack utilizing OpenStack::Client

=back

=head1 DESCRIPTION

A set of utility methods to accomplish common tasks on OpenStack utilizing OpenStack::Client.

=head1 INSTANTIATION

=head2 C<OpenStack::Utils-E<gt>new()>

E<10>

=head3 B<Simple Use case>

E<10>

    my $auth = {
        # Defaults to 3.
        'version' => 3,
        'endpoint' => 'https://bigreddog.namedclifford.com:5001/'
        'tenant' => $project_name,
        'username' => $username,
        'password' => $password,
    };

    $auth->{'scope'} = {
        'project' => {
            'name'   => 'someproject',
            'domain' => { 'name' => 'default' },
        },
    };

=item B<OR>

If you're only making a single request, pass the scope object that is required.

    my $auth = {
        'auth_endpoint' => 'https://bigreddog.namedclifford.com:5001/',
        'auth_request_body' => {
            'auth => {
                'identity' => {
                    'methods' => [ 'password' ],
                    'password' => {
                        'user' => {
                            'password' => '<password>',
                            'domain' => {
                                'name' => 'default'
                            },
                            'name' => 'admin'
                        }
                    } 
                }
                'scope' => {
                    'project' => {
                        'name'   => 'someproject',
                        'domain' => { 'name' => 'default' },
                    },
                },
            },
        },
    };

    my $request = {
        'method' => 'GET',
        'path' => '/servers/detail',
    };

=item B<Some callers or users may be admins.>

E<10>

    $request->{'body'} = {
        'all_tenants' => '1',
        'project_id' => 'bluedog@bigreddog.namedclifford.com',
    };    

    
=item B<Inital authentication and client creation;

E<10>

    my $os_util = OpenStack::Utils->new($auth);
    $os_util->set_service_client('compute');

=item B<OR>

    $request->{'service'} = 'compute';

    # If you didn't set your scope at object instantiation with the authentication object:

    $request->{'auth_request_body'}{'auth'}{'scope'} = {
        'project' => {
            'name'   => 'someproject',
            'domain' => { 'name' => 'default' },
        },
    };

    $os_util->request($request);



=item B<Pass an authentication scope in your request object.>

If scope needs to be set after initial autheniation for subsequent requests,
one can pass it as an auth scope object in the request object. 
If this is the first request after instantiation and a scope was not set at
instantiation, you should add a password method authentication object to the 
call to $os_util->request(). 

E<10>

    my $request = { . . . };

    $request->{'auth_requet_body'}{'auth'}{'scope'} = {
        'project' => {
            'domain' => {
                'name' => "default",
            },
        'name' => $project_name,
        },
    };

=item B<OR>

    $request->{'auth_request_body'}{'auth'}{'scope'} = {
        'system' => { 
            "all" => 'true' 
        },
    },

=item $request object can store data for processing the response.

Since it's passed to the response handler, you can add arbitrary keys and
values to the request for handling responses in a subclass. See examples/Util_examples/
subclass_libs/Intercept.pm. Complex handling and filtering can be performed on 
collections of responses using this technique.

    $request->{'label'} = 'hypervisor-server-search-project';

See example/Utils_example/subclass_libs/Intercept.pm and the corresponding get_server_hv.pl


=cut

sub new {
    my $class = shift;
    my $auth  = shift;
    my $self  = {};
    bless $self, $class;
    $self->set_auth($auth);
    return $self;
}

=head1 B<PUBLIC OBJECT INSTANCE METHODS>

=head2 Name: B<set_auth>

=head3 Usage: 

    $self->set_auth($auth);

=item B<Description:>

Authenticates and returns the client specified in the $opts->{'service'}
argument hash and available in the $auth->{'tokens'}->{'catalog'}
returned from the authentication call.

=back

=cut

sub set_auth {
    my $self = shift;
    my $auth = shift;
    $auth = $self->auth_overrides($auth);
    $auth->{'version'} //= 3;
    my $endpoint = $auth->{'endpoint'} . "v" . $auth->{'version'};
    my $auth_args;
    if ( ref $auth->{'auth_request_body'} eq "HASH" ) {
        $auth_args = { 
            'request' => { %{ $auth->{'auth_request_body'} } }
        };
    } 
    else  {
        $auth_args = {
            'tenant'  => $auth->{'tenant'},
            'password' => $auth->{'password'},
            'username' => $auth->{'username'},
            'scope'    => $auth->{'scope'},
            'version'  => $auth->{'version'}
        };
    }
    $self->{'auth'} = OpenStack::Client::Auth->new(
        $endpoint,
        %$auth_args,
        'version' => $auth->{'version'}
    );
    return $self;
}

=head2 Name: B<request>

=head3 Usage: C<$self-<gt>request($request, $auth)>

=item B<Description>

tl;dr C<$request->{'auth_request_body'}->{'scope'}> should only be passed with intention.

=over 2

Send the request using OpenStack::Client::call().

If an authentication scope object is sent with the request. A scope change
will be attempted (reauthentication) with the existing token if it exists.

If there is not an existing token, an authenticatoin object should be passed
with the password authentication method or a token provided outside of this
utility library. Outside of object instantiation, this need shouldn't arise.
but that possibility is addressed in C<set_scope()>.

Selects the appropriate OpenStack::Client using set_service_client.

=item Response handlers and the request payload.

Another interesting point about the request object is that it can carry information
about how the response should be handled as it is passed to the response handler
method which can easily be overriden in a subclass. 

Example:

C<$request-<gt>{'label'} = 'hypervisor-server-search'>

See example/Utils_example/subclass_libs/Intercept.pm and the corresponding get_server_hv.pl

=item Request object:

{
    # Service needed for the request.
    'service' => 'compute',
    'method' => 'GET',
    'path' => '/servers/detail',
    # Auth scope required for the request.
    'auth' => {
        'scope' => { 
            'project' => {
                'name'   => 'someproject',
                'domain' => { 'name' => 'default' },
            },
        },
    },
    'body' => { 
        '<body details>'
    },
}


=back

=cut

sub request {
    my $self    = shift;
    my $request = shift;
    my $new_auth->{'auth_request_body'} = $request->{'auth_request_body'};
    $request = $self->request_overrides($request);

    # initial request or if scope changes for new request.
    if ( $new_auth->{'auth_request_body'}{'auth'}{'scope'} ) {
        $self->set_scope($new_auth);
    }
    $self->set_service_client( $request->{'service'} );
    my $response = $self->{'service_client'}->call($request);
    $response = $self->handle_response( $response, $request );
    return $response;
}

=head2 Name: B<set_service_client>

=head3 Usage: C<$os_util-<gt>set_service_client($new_service_name)

=item B<Description> 

Sets the service used. Examples: "compute", "identity", "image", etc.

=cut

sub set_service_client {
    my $self    = shift;
    my $new_svc = shift;
    $self->{'service_client'} = $self->{'auth'}->service($new_svc);
    return $self;
}

=head2 Name: set_scope()

=head3 Usage: C<$self-<gt>set_scope($auth)>

=item B<Description>: Allows setting the scope and user for requests.

Authenticates to either change scope with an existing token after object 
instantiation or set scope on the initial request when there is not an existing
token.

If an $auth object is supplied to this method, that will take precendence over any 
existing token to allow user switching as well.

=cut 

sub set_scope {
    my $self = shift;
    my $auth = shift;
    if ( !$auth->{'auth_request_body'}{'auth'}{'identity'} ) {
        if ( $self->{'auth'}->token() ) {
            my $token = $self->{'auth'}->token();
            $auth->{'auth_request_body'}{'auth'}{'identity'} = {
                'methods' => ['token'],
                'token'   => { 'id' => $token }
            };
        }
        else {
            warn "Attempt to change scope without re-authentication. This isn't possible. Scope is unchanged.";
        }
    }
    $self->set_auth($auth);
}

=head1 B<REQUEST OVERRIDES>

This is a placeholder for subclass overrides to do work on the request.

See example/Utils_example/subclass_libs/Intercept.pm and the corresponding get_server_hv.pl

=head2 Arugments 2

=item The Utils object.

=item The full request object.

=cut

sub request_override { return $_[1]; }

=head1 RESPONSE HANDLER.

This is a placeholder for subclass overrides to do work on the response.

See example/Utils_example/subclass_libs/Intercept.pm and the corresponding get_server_hv.pl

=head2 Arguments 3

=item The Utils object.

=item The response object.

=item The request object.

=cut

sub handle_response { return $_[1]; }

=head1 AUTHENTICATION OVERRIDES

This is a placeholder for subclass overrides to do work on the authentication object.

See example/Utils_example/subclass_libs/Intercept.pm and the corresponding get_server_hv.pl

=head2 Arguments 2

=item The Utils object

=item The authentication object.

=cut

sub auth_overrides { return $_[1]; }

1;
