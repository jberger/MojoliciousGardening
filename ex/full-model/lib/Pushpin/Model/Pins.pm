package Pushpin::Model::Pins;

use Mojo::Base -base, -signatures;

has sqlite => sub { die 'sqlite is required' };

sub db ($self) { $self->sqlite->db }

sub all ($self) { $self->db->select('pins')->hashes }

sub create ($self, $pin) { $self->db->insert(pins => $pin) }

sub remove ($self, $id) {
  $self->db->delete(pins => { id => $id });
}

1;

