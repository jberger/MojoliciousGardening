package Pushpin::Controller::Pins;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub all ($c) { $c->render(json => $c->pins) }

sub create ($c) {
  $c->db->insert(pins => $c->req->json);
  $c->rendered(204);
}

sub map { }

sub remove ($c) {
  $c->db->delete(pins => { id => $c->param('id') });
  $c->redirect_to('table');
}

sub table { }

1;

