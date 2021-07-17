package Dist::Zilla::Plugin::ReleaseStatus::FromMetaJSON;

our $VERSION = '0.995';

use v5.10;
use JSON::MaybeXS qw();
use Moose;
with 'Dist::Zilla::Role::ReleaseStatusProvider';

sub provide_release_status {
    my ($self) = @_;
    my ($file) = grep { $_->name eq 'META.json' } @{ $self->zilla->files };
    my $ref    = JSON::MaybeXS->new()->utf8->decode($file->encoded_content);

    my $status = $ref->{'release_status'};
    return $status unless $status;
    if ($status eq 'unstable') {
        $self->log(['Releasing an unstable version']);
    } elsif ($status eq 'testing') {
        $self->log(['Releasing a testing version']);
    } else {
        $self->log(['Releasing a stable version']);
    }

    return $status;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ReleaseStatus::FromMetaJSON - Set release status from META.json

=head1 VERSION

version 0.995

=head1 DESCRIPTION

Retrieves the release status of the distribution from an already-generated META.json file.

This is useful for people that want to keep their repository 'as close to released as possible'

=for Pod::Coverage provide_release_status

=head1 AUTHORS

=over 4

=item *

Curtis Jewell <CSJewell@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis Jewell

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
