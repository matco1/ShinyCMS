# ===================================================================
# File:		t/controllers/controller-Pages.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS page features
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Fetch site homepage a few different ways, to test default section/page code
$t->get_ok(
	'/pages',
	'Fetch /pages'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded default CMS page (specified controller but not section or page)'
);
$t->get_ok(
	'/pages/home',
	'Fetch /pages/home'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded default CMS page (specified controller and section but not page)'
);
$t->get_ok(
	'/pages/home/home',
	'Fetch /pages/home/home'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded default CMS page (specified controller, section, and page)'
);
# Load a different CMS page in a different section
$t->follow_link_ok(
	{ text => 'Feature List' },
	"Follow link to 'feature list' page"
);
$t->title_is(
	'Feature List - ShinySite',
	'Loaded feature list page'
);
# Load a section with no default page configured
$t->follow_link_ok(
	{ text => 'More' },
	"Follow link to 'More' section"
);
$t->title_is(
	'About ShinyCMS - ShinySite',
	"Loaded 'About ShinyCMS' page - the first page in that section"
);

# Try to preview a page without Editor/Admin privs
$t->post_ok(
	'/pages/home/home/preview',
	{
		title => 'This Preview Will Fail'
	},
	'Attempt to preview changes to /pages/home/home without admin privs'
);
$t->text_contains(
	'You must be logged in to preview page edits',
	'Got appropriate error message'
);

# Test 404 handling
$t->get( '/pages/NO_SUCH_SECTION' );
ok(
	$t->status == 404,
	'Trying to visit missing section gets 404 error'
);
$t->title_is(
	'Page Not Found - ShinySite',
	'404 page loads instead'
);
$t->content_contains(
	'<form id="search" action="/search" method="post">',
	'404 page includes site search form'
);
$t->get( '/pages/home/NO_SUCH_PAGE' );
ok(
	$t->status == 404,
	'Trying to visit missing page in valid section also gets 404 error'
);

# ...

# Test some failure conditions in utility methods
my $c = $t->ctx;
my $P = 'ShinyCMS::Controller::Pages';

my $orig_default_section_name = $P->default_section( $c );
my $orig_default_section_id   = $c->stash->{ section }->id;
my $orig_default_section      = $c->stash->{ section };

ok(
	$orig_default_section_name eq 'home',
	"Confirmed that the original default section url_name is 'home'"
);
my $orig_default_page_name = $P->default_page( $c );
my $orig_default_page = $c->stash->{ page };
ok(
	$orig_default_page_name eq 'home',
	"Confirmed that the original default page url_name is 'home'"
);

$c->stash->{ section }->update({ default_page => undef });
my $fallback_default_page_name = $P->default_page( $c );
ok(
	$fallback_default_page_name eq 'contact-us',
	"Confirmed that the fallback default page url_name is 'contact-us'"
);

delete $c->stash->{ section };
{
	open STDERR, '>', File::Spec->devnull() or die "Could not open STDERR: $!";

	my $no_default_page_found = $P->default_page( $c ) ? 0 : 1;
	ok(
		$no_default_page_found,
		'Removed section from stash, verified that default page cannot be found'
	);

	# Create an empty section and try to find its default page
	my $empty = $c->model( 'DB::CmsSection' )->find_or_create({
		name     => 'Empty Test Section',
		url_name => 'empty'
	});
	$c->stash->{ section } = $empty;
	my $empty_page = $P->default_page( $c );
	my $undef_page = $empty_page ? 0 : 1;
	ok(
		 $undef_page,
		 'default_page() returned undef for section with no pages'
	);
	# TODO: Better test here, something like this. Use Try::Tiny?
	#ok(
	#	 STDERR =~ m{stashed section has no pages},
	#	 'Got warning for calling default_page() on section with no pages'
	#);
}

# Exercise the default/fall-through page handler for sites with no content
$P->no_page_data( $c );
ok(
	$c->response->body =~ m{If you are the site admin, please add some content},
	'Got expected fall-through text when calling no_page_data() directly'
);


# Tidy up
$orig_default_section->update({ default_page => $orig_default_section_id });

done_testing();
