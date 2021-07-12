package Dist::Zilla::Plugin::PerlTidy::WithExclusions;

our $VERSION = v0.001;

use v5.10;
use Perl::Tidy qw();
use Moose;
with(
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':AllFiles' ],
    },
);

has 'perltidyrc' => ( is => 'ro' );

has exclusions => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

sub mvp_multivalue_args { qw(exclusions) }

sub munge_files {
    my ($self) = @_;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ( $self, $file ) = @_;

    return $self->_munge_perl($file) if $file->name =~ /\.(?:pm|pl|t)$/i;
    return if -B $file->name;    # do not try to read binary file
    return $self->_munge_perl($file) if $file->content =~ /^#!.*\bperl\b/;
    return;
}

sub _munge_perl {
    my ( $self, $file ) = @_;

    return if ref($file) eq 'Dist::Zilla::File::FromCode';
    return if $file->name && $file->name =~ m{^blib/};
    return
        if $file->name
        and scalar grep { $file->name =~ /$_/ } @{ $self->exclusions };

    my $perltidyrc;
    if ( defined $self->perltidyrc ) {
        if ( -r $self->perltidyrc ) {
            $perltidyrc = $self->perltidyrc;
        } else {
            $self->log_fatal(
                [ 'specified perltidyrc is not readable: %s', $perltidyrc ] );
        }
    }

    # make Perl::Tidy happy
    local @ARGV = ();

    $self->log_debug([ 'Perltidying %s', $file->name, ]);

    my $source = $file->content;
    my ($destination, $errors);
    Perl::Tidy::perltidy(
        source      => \$source,
        destination => \$destination,
	stderr      => \$errors,
	argv        => ['--standard-error-output'],
        ( $perltidyrc ? ( perltidyrc => $perltidyrc ) : () ),
    );

    $self->log([ 'Errors from perltidying %s: %s', $file->name, $errors, ])
        if $errors;
    
    $file->content($destination);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PerlTidy::WithExceptions - PerlTidy in Dist::Zilla

=head1 VERSION

version 0.001

=head1 METHODS

=head2 munge_file

Implements the required munge_file method for the
L<Dist::Zilla::Role::FileMunger> role, munging each Perl file it finds.
Files whose names do not end in C<.pm>, C<.pl>, or C<.t>, or whose contents
do not begin with C<#!perl> are left alone.

=head2 SYNOPSIS

    # dist.ini
    [PerlTidy::WithExclusions]
    exceptions = ^share

    # or
    [PerlTidy::WithExclusions]
    perltidyrc = xt/.perltidyrc
    exceptions = ^share

=head2 DEFAULTS

If you do not specify a specific perltidyrc in dist.ini it will try to use
the same defaults as Perl::Tidy.

=head2 SEE ALSO

L<Perl::Tidy>

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Mark Gardner <mjgardner@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Curtis Jewell <csjewell@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Fayland Lam, 2021 by Curtis Jewell

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
