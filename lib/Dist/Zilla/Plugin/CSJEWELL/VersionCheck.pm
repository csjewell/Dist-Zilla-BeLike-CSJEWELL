package Dist::Zilla::Plugin::CSJEWELL::VersionCheck;

use v5.10.1;

use Moose;

use ExtUtils::MakeMaker qw();
use IO::String          qw();
use Pod::Text           qw();

with
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::Git::Repo',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    }
;

our $VERSION = '0.995';

has _git_version => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_git_version',
);

sub _build_git_version {
    my ($self) = @_;

    my ($current_tag) = $self->git->describe({ abbrev => ' 0', });
    if (!defined($current_tag)) {
        ($current_tag) = $self->git->rev_list('HEAD');
	# TODO: Check to see whether this needs split. We want [-1].
    };

    $current_tag;
}

has _files_list => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_files_list',
);

sub _build_files_list {
    my ($self) = @_;

    my $current_tag = $self->_git_version;

    my (@files_list) = $self->git->diff('--name-only', "$current_tag..HEAD");
    push @files_list, ($self->git->diff('--name-only'));

    \@files_list;
}

sub force { 0 } # TODO: Implement as arg.

sub munge_files {
    my ($self) = @_;

    $self->log(['Checking files updated since %s', $self->_git_version]);

    my %changed_files = map { $_ => 1 } @{ $self->_files_list }; 
    my @files_needing_updated;

    foreach my $file (@{ $self->found_files }) {
        next unless $self->force || $changed_files{ $file->name };
    	my $resp = $self->check_file($file);
	if ($resp) {
	    push @files_needing_updated, $file->name . ": $resp";
	}
    }

    if (scalar @files_needing_updated) {
        $self->log_fatal(['Need to update files to version %s: %s', $self->zilla->version, join("\n    ", '', @files_needing_updated)]);
    }

    return 1;
}

sub check_file {
    my ($self, $file) = @_;

    my $current_version = $self->zilla->version;

    my $version = MM->parse_version($file->name);
    if ($current_version ne $version) {
        return "\$VERSION found was not $current_version";
    }

    my $pod    = '';
    my $pod_fh = IO::String->new($pod);
    my $parser = Pod::Text->new();
    $parser->output_fh($pod_fh);
    $parser->parse_string_document($file->content);

    #pos($pod) = 0;
    while ($pod =~ /(version\s+[0-9.]+)/g) {
        my $found = $1;
	$found =~ s/[.]\z//;
	$found =~ s/\s+/ /;
	next if $found eq 'version 5.8.1'; # Bypass license text.
        return qq{Found "$found" in POD that needs to be "version $current_version"}
	    unless $found eq "version $current_version";
    }

    # Check only .pm files within the lib directory, plus specific inclusions.
    # Filter out 'v' from the tab, unless the version includes it.

    return 0;
} ## end sub munge_file

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::CSJEWELL::VersionCheck - Checks to see that all version numbers are updated that need to be.

=head1 VERSION

This document describes Dist::Zilla::Plugin::CSJEWELL::VersionCheck version 0.995.

=head1 DESCRIPTION

This checks for files that have changed.

Only files that have changed since the last version are checked, unless the force parameter is on.

=for Pod::Coverage before_build

=head1 AUTHOR

Curtis Jewell <CSJewell@cpan.org>

=head1 SEE ALSO

L<Dist::Zilla::BeLike::CSJEWELL|Dist::Zilla::BeLike::CSJEWELL>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< CSJewell@cpan.org >>.

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

