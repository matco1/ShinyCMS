# ===================================================================
# File:		t/admin-controllers/controller_Admin-Blog.t
# Project:	ShinyCMS
# Purpose:	Tests for blog admin features
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

use lib 't/support';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin',
    'Fetch admin area'
);
# Add a blog post
$t->follow_link_ok(
    { text => 'New blog post' },
    'Follow link to add a new blog post'
);
$t->title_is(
	'New blog post - ShinyCMS',
	'Reached page for adding blog post'
);
$t->submit_form_ok({
    form_id => 'add_post',
    fields => {
        title => 'This is a test blog post',
        body  => 'This is some test content.'
    }},
    'Submitted form to create blog post'
);
$t->title_is(
	'Edit blog post - ShinyCMS',
	'Redirected to edit page for newly created blog post'
);
my @inputs1 = $t->grep_inputs({ name => qr/url_title$/ });
ok(
    $inputs1[0]->value eq 'this-is-a-test-blog-post',
    'Verified that blog post was created'
);
# Update blog post
$t->submit_form_ok({
    form_id => 'edit_post',
    fields => {
        title => 'Blog post updated by test suite'
    }},
    'Submitted form to update blog post'
);
my @inputs2 = $t->grep_inputs({ name => qr/title$/ });
ok(
    $inputs2[0]->value eq 'Blog post updated by test suite',
    'Verified that blog post was updated'
);
# Delete blog post (can't use submit_form_ok due to javascript confirmation)
my $edit_url = $t->form_id( 'edit_post' )->action;
$edit_url =~ m{/(\d+)/edit-do$};
my $id = $1;
$t->post_ok(
    '/admin/blog/post/'.$id.'/edit-do',
    {
        delete => 'Delete'
    },
    'Submitted request to delete blog post'
);
# View list of blog posts
$t->title_is(
    'Blog Posts - ShinyCMS',
    'Reached list of blog posts'
);
$t->content_lacks(
    'Blog post updated by test suite',
    'Verified that blog post was deleted'
);
# Reload the blog admin area to give the index() method some exercise
$t->get_ok(
    '/admin/blog',
    'Fetch blog admin area one last time'
);
$t->title_is(
	'Blog Posts - ShinyCMS',
	'Reloaded blog admin area via index method (yay, test coverage)'
);

remove_test_admin();

done_testing();