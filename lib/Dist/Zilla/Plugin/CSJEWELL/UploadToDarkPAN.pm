package Dist::Zilla::Plugin::UploadToDarkPAN;

our $VERSION = '0.995';

use Moose;
with 'Dist::Zilla::Role::Releaser';

use namespace::autoclean;

has ssh_username => (
    is       => 'ro',
    required => 1,
);

has copy_destination => (
    is       => 'ro',
    required => 1,
);

has post_copy_command => (
    is => 'ro',
);

sub release {
    my ($self, $archive) = @_;

    $self->uploader->upload_file("$archive");

    my @command = ('scp', $archive, join(':', $self->ssh_username, $ssh->copy_destination));

    $self->log([join ' ', 'Running command: ', @command]);
    my $ret = system @command;
    $ret == 0 or $self->log_fatal(['The command returned %i', $ret]);

    if ($self->post_copy_command) {
        @command = ('ssh', $self->ssh_username, $ssh->post_copy_command);
    	$self->log([join ' ', 'Running post-copy command: ', @command]);
	$ret = system @command;
    	$ret == 0 or $self->log_fatal(['The command returned %i', $ret]);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CSJEWELL::UploadToDPAN - upload the dist to CPAN

=head1 VERSION

version 0.995

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to a DarkPAN via SSH,
and run a command to rebuild the DarkPAN afterwards. 

=head1 DESCRIPTION

This plugin looks for configuration in your C<dist.ini> or (more
likely) C<~/.dzil/config.ini>:

  [CSJEWELL::UploadToDPAN]
  ssh_username = root@curtisjewell.website
  copy_destination = /var/www/darkpan
  post_copy_command = /root/dpan.sh

=head1 ATTRIBUTES

=head2 ssh_username



=head2 copy_destination



=head2 post_copy_command



=head1 AUTHOR

Curtis Jewell <csjewell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis Jewell.

...

=cut

