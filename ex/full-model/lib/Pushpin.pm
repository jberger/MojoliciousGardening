package Pushpin;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::SQLite;
use Pushpin::Model::Pins;

has sqlite => sub ($app) {
  my $conf = $app->config;
  my $sqlite = Mojo::SQLite->new($conf->{db})->auto_migrate(1);
  $sqlite->migrations->from_data;
  return $sqlite;
};

sub startup ($app) {
  $app->plugin(Config => {
    default => {
      db => 'pushpin.db',
      admin => 'bender',
    },
  });

  $app->helper('model.pins' => sub ($c) {
    Pushpin::Model::Pins->new(sqlite => $c->app->sqlite);
  });

  my $r = $app->routes;

  $r->get('/pins')->to('Pins#all');
  $r->post('/pins')->to('Pins#create');

  my $admin = $r->under('/admin')->to('Admin#check');
  $admin->get('/')->to('Pins#table')->name('table');
  $admin->delete('/:id')->to('Pins#remove')->name('remove');

  $r->any('/logout')->to('Admin#logout');
  $r->any('/*any' => {any => ''})->to('Pins#map')->name('map');
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

