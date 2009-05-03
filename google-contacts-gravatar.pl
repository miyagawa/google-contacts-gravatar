#!/usr/bin/perl
use strict;

package Google::Contacts::Gravatar;
use Gravatar::URL;
use Any::Moose;
use Net::Google::AuthSub;
use LWP::UserAgent;
use XML::LibXML::Simple;

with any_moose('X::Getopt');

has authsub => (
    is => 'rw', isa => 'Net::Google::AuthSub',
    default => sub { Net::Google::AuthSub->new(service => 'cp') },
    lazy => 1,
);

has agent => (
    is => 'rw', isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
    lazy => 1,
);

has auth_params => (
    is => 'rw', isa => 'HashRef',
);

has email => (
    is => 'rw', isa => 'Str', required => 1,
);

has password => (
    is => 'rw', isa => 'Str', required => 1,
);

has max_results => (
    is => 'rw', isa => 'Int', default => 1000,
);

has overwrite => (
    is => 'rw', isa => 'Bool', default => 0,
);

has contacts => (
    is => 'rw', isa => 'ArrayRef',
);

has debug => (
    is => 'rw', isa => 'Bool', default => 0,
);

sub run {
    my $self = shift;

    $self->authorize();
    $self->retrieve_contacts();
    $self->update_contacts_photos();
}

sub authorize {
    my $self = shift;

    my $resp = $self->authsub->login($self->email, $self->password);
    $resp->is_success or die "Auth failed against " . $self->email;
    $self->auth_params({ $self->authsub->auth_params });
}

sub retrieve_contacts {
    my $self = shift;

    my $feed = $self->get_feed("contacts/default/full?max-results=" . $self->max_results);
    $self->contacts($feed->{entry});
}

sub update_contacts_photos {
    my $self = shift;

    for my $contact (@{$self->contacts}) {
        my @email = grep defined, map $_->{address}, @{$contact->{"gd:email"} || []}
            or next;

        my ($has_photo) = grep $_->{rel} eq 'http://schemas.google.com/contacts/2008/rel#photo', @{$contact->{link}};
        if ($has_photo && !$self->overwrite) {
            warn "$email[0] has a photo. Skipping.\n" if $self->debug;
            next;
        }

        my($edit) = grep $_->{rel} eq 'http://schemas.google.com/contacts/2008/rel#edit-photo', @{$contact->{link}};

        for my $email (@email) {
            my $avatar = $self->find_avatar($email) or next;
            if ($avatar) {
                warn "Gravatar found for $email. Updating the photo.\n";
                $self->update_photo($edit->{href}, $avatar);
                last;
            }
        }
    }
}

sub find_avatar {
    my($self, $email) = @_;

    warn "Finding avatar for $email\n" if $self->debug;

    my $url = gravatar_url(email => $email, default => q(""));
    return $self->agent->get($url)->content;
}

sub update_photo {
    my($self, $uri, $photo) = @_;

    my $req = HTTP::Request->new(PUT => $uri);
    while (my($k, $v) = each %{$self->auth_params}) {
        $req->header($k, $v);
    }
    $req->content_type("image/jpeg");
    $req->content($photo);
    $req->content_length(length $photo);

    my $res = $self->agent->request($req);

    if ($res->is_success) {
        warn "Photo update was successful.\n";
    } else {
        warn "Photo update failed: ". $res->status_line;
    }
}

sub get_feed {
    my($self, $uri) = @_;

    my $res = $self->agent->get("http://www.google.com/m8/feeds/$uri", %{ $self->auth_params });
    $res->is_success or die "HTTP error for $uri: " . $res->status_line;

    return XML::LibXML::Simple->new->XMLin($res->content, KeyAttr => [], ForceArray => [ 'gd:email' ]);
}

package main;
Google::Contacts::Gravatar->new_with_options->run;



