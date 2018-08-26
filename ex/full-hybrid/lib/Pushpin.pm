package Pushpin;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::SQLite;

sub startup ($app) {
  my $config = $app->plugin(Config => {
    default => {
      db => 'pushpin.db',
      admin => 'bender',
    },
  });

  my $sqlite = Mojo::SQLite->new($config->{db})->auto_migrate(1);
  $sqlite->migrations->from_data;
  $app->helper(db => sub { $sqlite->db });

  $app->helper(all_pins => sub ($c) { $c->db->select('pins')->hashes });

  $app->helper(basic_auth => sub ($c) {
    $c->res->headers->www_authenticate('Basic realm=pushpin');
    $c->rendered(401);
    return 0;
  });

  my $r = $app->routes;

  $r->get('/pins' => sub ($c) { $c->render(json => $c->all_pins) });

  $r->post('/pins' => sub ($c) {
    $c->db->insert(pins => $c->req->json);
    $c->rendered(204);
  });

  my $admin = $r->under('/admin' => sub ($c) {
    return 1 if $c->session('admin');
    return $c->session(admin => 1) if $c->req->url->to_abs->username eq $config->{admin};
    return $c->basic_auth;
  });

  $admin->get('/' => 'table');

  $admin->delete('/:id' => sub ($c) {
    $c->db->delete(pins => { id => $c->param('id') });
    $c->redirect_to('table');
  } => 'remove');

  $r->any('/logout' => sub ($c) { $c->session(expires => 1)->basic_auth });

  $r->any('/*any' => {any => ''} => 'map');
}

1;

__DATA__

@@ migrations
-- 1 up
create table pins (
  id integer primary key,
  lat real,
  lng real,
  text text
);

