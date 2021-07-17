package Dist::Zilla::PluginBundle::Author::CSJEWELL;

use v5.10;
use Moose;
use Types::Standard qw(Bool ArrayRef Str);
with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';

our $VERSION = '0.995';

has fake_release => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
          $ENV{'DZIL_NO_RELEASE'}                 ? $ENV{'DZIL_NO_RELEASE'}
	: exists $_[0]->payload->{'fake_release'} ? $_[0]->payload->{'fake_release'}
        :                                           1;
    },
);

has perltidyrc => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{'perltidyrc'} ? $_[0]->payload->{'perltidyrc'} : 'xt/settings/perltidy.txt';
    },
);

has darkpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{'darkpan'} ? $_[0]->payload->{'darkpan'} : 0;
    },
);

has twitter => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
          $_[0]->fake_release                ? 0
	: exists $_[0]->payload->{'twitter'} ? $_[0]->payload->{'twitter'}
	:                                      0;
    },
);

has exclusions => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { exists $_[0]->payload->{'exclusions'} ? $_[0]->payload->{'exclusions'} : ['t/000-']; },
);

sub mvp_multivalue_args { qw(exclusions) }

sub configure {
    my ($self) = @_;

    my @plugins = (
	$self->fake_release ? ['CSJEWELL::FakeReleaseAnnounce'] : (),
        ['ReleaseStatus::FromMetaJSON'],
        ['CSJEWELL::BeforeBuild'],
        ['GatherDir'],
        ['ManifestSkip'],
        ['CSJEWELL::VersionGetter'],
        ['CSJEWELL::ModuleBuild'],
        ['CSJEWELL::VersionCheck'],
	['PerlTidy::WithExclusions' => { perltidyrc => $self->perltidyrc, exclusions => $self->exclusions }],

        ['ConfirmRelease'],
        ['RunExtraTests'],

        $self->fake_release ? (['FakeRelease']) : $self->darkpan ? (['CSJEWELL::UploadToDarkPAN']) : (['UploadToCPAN']),

	['Git::Check'],
	['Git::Commit'],
	$self->fake_release ? () : ['Git::Tag'],
	$self->fake_release ? () : ['Git::Push', { push_to => ['origin', 'github',], }],

	$self->twitter ? ['Twitter', {
            tweet         => 'Uploaded {{$DIST}} {{$VERSION}} to #CPAN - find it on your local mirror. {{$URL}} #perl',
            url_shortener => '',
        }] : (),
    );

    $self->add_plugins(@plugins);

    return $self;
} ## end sub configure

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::CSJEWELL - CSJEWELL's basic plugins to maintain and release CPAN dists

=head1 VERSION

This document describes Dist::Zilla::PluginBundle::Author::CSJEWELL version 0.995.

=head1 DESCRIPTION

This is meant to be a usable plugin bundle for those of us that want to check 
in everything, and have what is checked in be released, other than what can 
be generated from what IS checked in at 'Build dist' or 'dzil build' time, 
and that both of those generate an identical tarball.

The goal is that no plugin that creates or modifies a .pm, .pod, or .t file 
'on the fly' is in here.

It includes the following plugins with their default configuration:

=over 4

=item *

L<Dist::Zilla::Plugin::CSJEWELL::BeforeBuild|Dist::Zilla::Plugin::CSJEWELL::BeforeBuild>

=item *

L<Dist::Zilla::Plugin::GatherDir|Dist::Zilla::Plugin::GatherDir>

=item *

L<Dist::Zilla::Plugin::ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>

=item *

L<Dist::Zilla::Plugin::CSJEWELL::VersionGetter|Dist::Zilla::Plugin::CSJEWELL::VersionGetter>

=item *

L<Dist::Zilla::Plugin::TestRelease|Dist::Zilla::Plugin::TestRelease>

=item *

L<Dist::Zilla::Plugin::ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>

=item *

L<Dist::Zilla::Plugin::UploadToCPAN|Dist::Zilla::Plugin::UploadToDarkPAN> *

=item *

L<Dist::Zilla::Plugin::UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> *

=item *

L<Dist::Zilla::Plugin::FakeRelease|Dist::Zilla::Plugin::FakeRelease> *

=back

* Note that the choice of which the last three is given by two options to the
plugin bundle - if "fake_release" does not exist, or if it exists and is 1,
then FakeRelease is used, and if "darkpan" exists and is 1, then
CSJEWELL::UploadToDarkPAN is used. Otherwise, UploadToCPAN is used.

=for Pod::Coverage darkpan configure

=for stopword Makefile yml README

=head1 AUTHOR

Curtis Jewell <CSJewell@cpan.org>

=head1 SEE ALSO

L<Dist::Zilla::BeLike::CSJEWELL|Dist::Zilla::BeLike::CSJEWELL>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, 2021 Curtis Jewell C<< CSJewell@cpan.org >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

