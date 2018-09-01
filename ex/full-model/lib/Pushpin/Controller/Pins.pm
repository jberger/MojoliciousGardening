package Pushpin::Controller::Pins;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub all ($c) { $c->render(json => $c->model->pins->all) }

sub create ($c) {
  $c->model->pins->create($c->req->json);
  $c->rendered(204);
}

sub map { }

sub remove ($c) {
  $c->model->pins->remove($c->param('id'));
  $c->redirect_to('table');
}

sub table ($c) { $c->stash(pins => $c->model->pins->all) }

1;

