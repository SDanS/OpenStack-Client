package OpenStack::Client::Utils::Intercept;

use base qw{OpenStack::Client::Utils};
use Data::UUID;

use strict;
use warnings;

=pod

=head1 Name: B<OpenStack::Client::Utils::Intercept;

Example subclass to demonstrate overriding methods to control 
information in your environment. SEE THE FOLLOWING:

=item L<OpenStack::Client::Utils/"Request Overrides">

=item L<OpenStack::Client::Utils/""

=cut

#Request override data structure.
my $request_overrides = {};

### Request header overrides.
$request_overrides->{'header_overrides'} = { 'global_request_id' => \&global_request_id };

### Request body overrides.
$request_overrides->{'body_overrides'} = { 'project_id' => \&request_body_project_id };

### Authentication overrides.
my $auth_overrides = {
    'endpoint'          => 'https://bigreddog.namedclifford.com:5001/',
    'system-scope-true' => \&system_scope_true
};

### Response handlers.
my $response_handlers = {
    'labels' => {
        'hypervisor-server-search-nick' => \&hypervisor_server_search_someproject,
        'other_label'                   => \&another_label
    }
};

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    return $self;
}

=head1 AUTHENTICATION OVERRIDES

=cut

sub auth_overrides {
    my $self = shift;
    my $auth = shift;
    for my $k ( keys %{$auth_overrides} ) {
        if ( $auth_overrides->{$k} ) {
            ### Handle simple scalar value.
            $auth->{$k} = $auth_overrides->{$k}
                unless ref $auth_overrides->{$k};

            ### Handle coderefs;
            my $ao = $auth_overrides->{$k};
            $auth = $ao->($auth)
                if ref $ao eq "CODE";
        }
    }
    return $auth;
}

sub system_scope_true {
    my $auth = shift;
    my $scope;
    if ( exists $auth->{'auth_request_body'}{'auth'}{'scope'} ) {
        $scope = $auth->{'auth_request_body'}->{'auth'}->{'scope'};
        if ( exists $scope->{'system'} ) {
            if ( exists $scope->{'system'}{'all'} && $scope->{'system'}{'all'} =~ /\b[Tt]rue|1/ ) {
                $scope->{'system'}{'all'} = JSON::true;
            }
        }
    }
    return $auth;
}

=head1 RESPONSE HANDLERS

=cut

sub handle_response {
    my $self     = shift;
    my $response = shift;
    my $request  = shift;
    for my $k ( keys %{ $response_handlers->{'labels'} } ) {
        if ( $response_handlers->{'labels'}->{$k} ) {
            ### Handle coderefs;
            my $rh = $response_handlers->{'labels'}->{$k};
            $response = $rh->( $response, $request )
                if ref $rh eq "CODE";
        }
    }
    return $response;

}

sub hypervisor_server_search_nick {
    my $response = shift;
    my $request  = shift;
    return $response;
}

sub another_label {
    my $response = shift;
    my $request;
    warn("I\'m another label!");
    return $response;
}

=head1 REQUEST OVERRIDES

=cut

sub request_overrides {
    my $self    = shift;
    my $request = shift;
    $request = $self->request_header_override($request);
    $request = $self->request_body_override($request);
    return $request;
}

sub request_header_override {
    my $self;
    my $request     = shift;
    my $h_overrides = $request_overrides->{'header_overrides'};
    for my $k ( keys %{$h_overrides} ) {
        if ( $h_overrides->{$k} ) {
            ### Handle simple scalar value.
            $request->{'headers'}->{$k} = $h_overrides->{$k}
                unless ref $h_overrides->{$k};

            ### Handle coderefs;
            if ( ref $h_overrides->{$k} eq "CODE" ) {
                my $cr = $h_overrides->{$k};
                $request->{'headers'} = $cr->( $request->{'headers'} );
            }
        }
    }
    return $request;
}

sub request_body_override {
    my $self;
    my $request = shift;
    $request = $self->request_body_projects($request);
    return $request;
}

sub global_request_id {
    my $headers = shift;
    my $ug      = Data::UUID->new();
    $headers->{'X-Openstack-Request-Id'} = 'req-' . $ug->create_str();
    return $headers;
}

sub request_body_projects {
    my $request  = shift;
    my @verboden = (
        'yellerdogt@bigreddog.namedclifford.com',
        'bluedog@bigreddog.namedclifford.com'
    );
    if ( grep { $request->{'body'}->{'project_id'} eq $_ } @verboden ) {
        die "What are you doing?!";
    }
    return $request;
}

1;
