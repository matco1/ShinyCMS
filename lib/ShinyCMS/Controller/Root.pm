package ShinyCMS::Controller::Root;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Root

=head1 DESCRIPTION

Root Controller for ShinyCMS.

=cut


# Set the actions in this controller to be registered with no prefix, 
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config->{ namespace } = '';

# Top-level config items   (TODO: Pull out into Controller::Root config?)
has [qw/ recaptcha_public_key recaptcha_private_key upload_dir /] => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);

around BUILDARGS => sub {
	my( $orig, $self, $app, @rest ) = @_;
	my $args = $self->$orig( $app, @rest );
	$args->{ recaptcha_public_key  } = $app->config->{ 'recaptcha_public_key'  };
	$args->{ recaptcha_private_key } = $app->config->{ 'recaptcha_private_key' };
	$args->{ upload_dir            } = $app->config->{ 'upload_dir'            };
	return $args;
};


=head1 METHODS

=head2 base

Stash top-level config items, check for affiliate ID and set cookie if found

=cut

sub base : Chained( '/' ) : PathPart( '' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	my $now = DateTime->now;
	$c->stash(
		recaptcha_public_key  => $self->recaptcha_public_key,
		recaptcha_private_key => $self->recaptcha_private_key,
		upload_dir            => $self->upload_dir,
		now                   => $now,
	);
	
	if ( $c->request->param( 'affiliate' ) ) {
		$c->response->cookies->{ shinycms_affiliate } = 
			{ value => $c->request->param( 'affiliate' ) };
	}
}


=head2 index

Handle requests for / with the CMS pages index method

=cut

sub index : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Redirect to the default index page in the CMS pages section
	$c->detach( 'Pages', 'index' );
}


# ========== ( /login  /logout /admin ) ==========

=head2 login

Forward to the user-facing login action

=cut

sub login : Path( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'User', 'login' );
}


=head2 logout

Forward to the logout action

=cut

sub logout : Path( 'logout' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'User', 'logout' );
}


=head2 admin

Forward to the admin login action

=cut

sub admin : Path( 'admin' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'Admin::Users', 'login' );
}


# ========== ( Search and Site Map ) ==========

=head2 search

Display search form, process submitted search forms.

=cut

sub search : Chained( 'base' ) : PathPart( 'search' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param( 'search' ) ) {
		$c->forward( 'Pages',      'search' );
		$c->forward( 'News',       'search' );
		$c->forward( 'Blog',       'search' );
		$c->forward( 'Forums',     'search' );
		$c->forward( 'Discussion', 'search' );
		$c->forward( 'Events',     'search' );
		$c->forward( 'Shop',       'search' );
		# TODO: the rest ...
	}
}


=head2 sitemap

Generate a sitemap.

=cut

sub sitemap : Chained( 'base' ) : PathPart( 'sitemap' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my @sections = $c->model( 'DB::CmsSection' )->all;
	$c->stash->{ sections } = \@sections;
}


# ========== ( Stylesheet / Mobile overrides ) ==========

=head2 switch_style

Set (or clear) stylesheet overrides.

=cut

sub switch_style : Chained( 'base' ) : PathPart( 'switch-style' ) : Args( 1 ) {
	my ( $self, $c, $style ) = @_;
	
	if ( $style eq 'default' ) {
		# Clear any style overrides
		$c->response->cookies->{ stylesheet } = { value => '', expires => '-1Y' };
	}
	else {
		# Set the cookie for a style override
		$c->response->cookies->{ stylesheet } = { value => $style };
	}
	
	$c->response->redirect( $c->uri_for( '/' ) );
	$c->response->redirect( $c->request->referer ) if $c->request->referer;
}


=head2 mobile_override

Set (or clear) an override flag for the mobile device detection

=cut

sub mobile_override : Chained( 'base' ) : PathPart( 'mobile-override' ) : Args( 1 ) {
	my ( $self, $c, $condition ) = @_;
	
	if ( $condition eq 'on' ) {
		$c->response->cookies->{ mobile_override } = { value => 'on' };
	}
	elsif ( $condition eq 'off' ) {
		$c->response->cookies->{ mobile_override } = { value => 'off' };
	}
	else {
		$c->response->cookies->{ mobile_override } = { value => '', expires => '-1Y' };
	}
	
	$c->response->redirect( $c->uri_for( '/' ) );
	$c->response->redirect( $c->request->referer ) if $c->request->referer;
}


# ========== ( utility methods ) ==========

=head2 stash_shared_content

Stash shared content for use across site.

=cut

sub stash_shared_content {
	my ( $self, $c ) = @_;
	
	# Get shared content elements
	my @elements = $c->model( 'DB::SharedContent' )->all;
	foreach my $element ( @elements ) {
		$c->stash->{ shared_content }->{ $element->name } = $element->content;
	}
}


=head2 get_filenames

Get a list of filenames from a specified folder in the uploads area.

=cut

sub get_filenames {
	my ( $self, $c, $folder ) = @_;
	
	$folder ||= 'images';
	
	my $image_dir = $c->path_to( 'root', 'static', $c->config->{ upload_dir }, $folder );
	opendir( my $image_dh, $image_dir ) 
		or die "Failed to open image directory $image_dir: $!";
	
	my $images = [];
	foreach my $filename ( readdir( $image_dh ) ) {
		push @$images, $filename unless $filename =~ m/^\./; # skip hidden files
	}
	@$images = sort @$images;
	
	return $images;
}


# ========== ( Output rendering ) ==========

=head2 default

404 handler

=cut

sub default {
	my ( $self, $c ) = @_;
	
	$c->stash->{ template } = '404.tt';
	
	$c->response->status( 404 );
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass( 'RenderView' ) {
	my ( $self, $c ) = @_;
	
	# Detect mobile devices and set a flag
	my $browser = $c->request->browser;
	$c->stash->{ meta }->{ mobile_device } = 'Yes' if $browser->mobile;
	
	# Check for mobile detection override cookie, set appropriate flag
	if ( $c->request->cookies->{ mobile_override } ) {
		my $override = $c->request->cookies->{ mobile_override }->value;
		
		if ( $override eq 'on' ) {
			$c->stash->{ meta }->{ mobile_override_on  } = 'Always treat as mobile';
		}
		else { # off
			$c->stash->{ meta }->{ mobile_override_off } = 'Always treat as desktop';
		}
	}
	
	# Configure stylesheet overrides based on prefs in cookies, if any
	# TODO: extend this to find multiple cookies and apply all specified styles
	if ( $c->request->cookies->{ stylesheet } ) {
		my $sheet = $c->request->cookies->{ stylesheet }->value;
		
		my @sheets;
		push @sheets, $sheet;
		$c->stash->{ meta }->{ stylesheets } = \@sheets;
	}
	
	# Stash the shared content, if any
	$self->stash_shared_content( $c );
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
