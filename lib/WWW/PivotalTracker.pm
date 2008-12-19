package WWW::PivotalTracker;

use warnings;
use strict;

use parent 'Exporter';

use Perl6::Parameters;

use aliased 'HTTP::Request'  => '_Request';
use aliased 'LWP::UserAgent' => '_UserAgent';

use Carp qw/
    croak
/;
use XML::Simple qw/
    XMLin
    XMLout
/;

=head1 NAME

WWW::PivotalTracker - The great new WWW::PivotalTracker!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module provides simple methods to interact with the Pivotal Tracker API.

    use WWW::PivotalTracker qw/
        project_details
    /;

    my $details = project_details("API Token", "Project ID");

    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut

our @EXPORT_OK = qw/
    add_story
    delete_story
    project_details
/;

=head1 FUNCTIONS

=head2 project_details


=cut

sub project_details($token, $project_id) {
    croak("Malformed Project ID: '$project_id'") unless __PACKAGE__->_check_project_id($project_id);

    my $response = __PACKAGE__->_do_request($token, "projects/$project_id", "GET");


    if (!defined $response || $response->{'success'} ne 'true') {
        return {
            success => 'false',
            errors  => (defined $response && exists $response->{'errors'} ? $response->{'errors'} : 'Epic fail!'),
        };
    }

    return {
        success         => 'true',
        iteration_weeks => $response->{'project'}->{'iteration_length'}->{'content'},
        name            => $response->{'project'}->{'name'},
        point_scale     => $response->{'project'}->{'point_scale'},
        start_day       => $response->{'project'}->{'week_start_day'},
    };
}

=head2 add_story

=cut

sub add_story($token, $project_id, $story_details)
{
    croak("Malformed Project ID: '$project_id'") unless __PACKAGE__->_check_project_id($project_id);

    foreach my $key (keys %$story_details) {
        croak("Unrecognized option: $key")
            unless _is_one_of($key, [qw/
                created_at
                current_state
                description
                estimate
                labels
                name
                note
                requested_by
                story_type
            /]);
    }
    croak("Name is required for a new story") unless exists $story_details->{'name'};
    croak("Requested By is required for a new story") unless exists $story_details->{'requested_by'};

    my $content = __PACKAGE__->_make_xml({ story => $story_details });

    my $response = __PACKAGE__->_do_request($token, "projects/$project_id/stories", "POST", $content);

    if (!defined $response || $response->{'success'} ne 'true') {
        return {
            success => 'false',
            errors  => $response->{'errors'},
        };
    }

    my $story = $response->{'story'}->[0];
    return {
        success       => 'true',
        id            => $story->{'id'}->{'content'},
        name          => $story->{'name'},
        description   => $story->{'description'},
        estimate      => $story->{'estimate'}->{'content'},
        current_state => $story->{'current_state'},
        created_at    => $story->{'created_at'},
        story_type    => $story->{'story_type'},
        requested_by  => $story->{'requested_by'},
        labels        => (exists $story->{'labels'} ? $story->{'labels'}->{'label'} : undef),
        url           => $story->{'url'},
    };
}

sub delete_story($token, $project_id, $story_id)
{
    croak("Malformed Project ID: '$project_id'") unless __PACKAGE__->_check_project_id($project_id);
    croak("Malformed Project ID: '$project_id'") unless __PACKAGE__->_check_story_id($project_id);

    my $response = __PACKAGE__->_do_request($token, "projects/$project_id/stories/$story_id", "DELETE", undef);

    if (!defined $response || $response->{'success'} ne 'true') {
        return {
            success => 'false',
            errors  => $response->{'errors'},
        };
    }

    my $message = $response->{'message'};
    return {
        success => 'true',
        message => $message,
    };
}

sub _check_story_id($class, $story_id)
{
    return $story_id =~ m/^\d+$/ ? 1 : 0;
}

sub _check_project_id($class, $project_id)
{
    return $project_id =~ m/^\d+$/ ? 1 : 0;
}

sub _is_one_of($element, $set)
{
    return((scalar grep { $_ eq $element } @$set) ? 1 : 0);
}

sub _do_request($class, $token, $request_url, $request_method; $content)
{
    my $base_url = "https://www.pivotaltracker.com/services/v1/";

    my $request = _Request->new(
        $request_method,
        $base_url . $request_url,
        [
            'X-TrackerToken' => $token,
            'Content-type'   => 'application/xml',
        ],
        $content
    );

    my $response = $class->_post_request($request);
    croak($response->status_line()) unless ($response->is_success());

    print $response->content();

    return XMLin(
        $response->content(),
        ForceArray => [qw/
            error
            iteration
            label
            note
            story
        /],
        GroupTags => {
            errors => 'error',
            labels => 'label',
        },
        KeyAttr => [],
        SuppressEmpty => undef,
    );
}

sub _post_request($class, $request)
{
    my $ua = _UserAgent->new();

    return $ua->request($request);
}

sub _make_xml($class, HASH $data)
{
    return XMLout(
        $data,
        AttrIndent => 0,
        KeepRoot   => 1,
        NoAttr     => 1,
    );
}

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pivotaltracker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PivotalTracker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PivotalTracker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PivotalTracker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PivotalTracker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PivotalTracker>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PivotalTracker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Jacob Helwig, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::PivotalTracker
