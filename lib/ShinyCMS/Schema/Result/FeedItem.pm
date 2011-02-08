package ShinyCMS::Schema::Result::FeedItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

ShinyCMS::Schema::Result::FeedItem

=cut

__PACKAGE__->table("feed_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 feed

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 1

=head2 posted

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "feed",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "body",
  { data_type => "text", is_nullable => 1 },
  "posted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 feed

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Feed>

=cut

__PACKAGE__->belongs_to(
  "feed",
  "ShinyCMS::Schema::Result::Feed",
  { id => "feed" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-02-07 22:18:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sZb3YXVPrs249pL+yAKnTQ


=head2 teaser

Return the specified number of leading paragraphs from the body text

=cut

sub teaser {
	my ( $self, $count ) = @_;
	
	$count ||= 1;
	
	my @paragraphs = split '</p>', $self->body;
	
	my $teaser = '';
	my $i = 1;
	foreach my $paragraph ( @paragraphs ) {
		$teaser .= $paragraph .'</p>';
		last if $i++ >= $count;
	}
	
	return $teaser;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

