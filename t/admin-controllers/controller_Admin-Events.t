# ===================================================================
# File:		t/admin-controllers/controller_Admin-Events.t
# Project:	ShinyCMS
# Purpose:	Tests for event admin features
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
# Add a new event
$t->follow_link_ok(
    { text => 'Add new event' },
    'Follow link to add a new event'
);
$t->title_is(
	'Add event - ShinyCMS',
	'Reached page for adding new event'
);
$t->submit_form_ok({
    form_id => 'add_event',
    fields => {
        name       => 'This is a test event',
        start_date => DateTime->now->ymd,
        end_date   => DateTime->now->ymd,
    }},
    'Submitted form to create new event'
);
$t->title_is(
	'Edit event - ShinyCMS',
	'Redirected to edit page for newly created event'
);
my @inputs1 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
    $inputs1[0]->value eq 'this-is-a-test-event',
    'Verified that event was created'
);
# Update event
$t->submit_form_ok({
    form_id => 'edit_event',
    fields => {
        name => 'Updated test event'
    }},
    'Submitted form to update event'
);
my @inputs2 = $t->grep_inputs({ name => qr/^name$/ });
ok(
    $inputs2[0]->value eq 'Updated test event',
    'Verified that event was updated'
);
# Delete event (can't use submit_form_ok due to javascript confirmation)
my @inputs3 = $t->grep_inputs({ name => qr/^event_id$/ });
my $id = $inputs3[0]->value;
$t->post_ok(
    '/admin/events/edit-event-do/'.$id,
    {
        event_id => $id,
        delete   => 'Delete'
    },
    'Submitted request to delete event'
);
# View list of events
$t->title_is(
    'List Events - ShinyCMS',
    'Reached list of events'
);
$t->content_lacks(
    'Updated test event',
    'Verified that event was deleted'
);

remove_test_admin();

done_testing();