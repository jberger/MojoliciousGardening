package Pushpin;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::SQLite;

# sample(sqlite)
has sqlite => sub ($app) {
  my $conf = $app->config;
  my $sqlite = Mojo::SQLite->new($conf->{db})->auto_migrate(1);
  $sqlite->migrations->from_data;
  return $sqlite;
};
# end-sample

sub startup ($app) {
  $app->plugin(Config => {
    default => {
      db => 'pushpin.db',
      admin => 'bender',
    },
  });

  $app->helper(db => sub ($c) { $c->app->sqlite->db });

  $app->helper(pins => sub ($c) { $c->db->select('pins')->hashes });

  my $r = $app->routes;

  # sample(routes)
  $r->get('/pins')->to('Pins#all');
  $r->post('/pins')->to('Pins#create');

  my $admin = $r->under('/admin')->to('Admin#check');
  $admin->get('/')->to('Pins#table')->name('table');
  $admin->delete('/:id')->to('Pins#remove')->name('remove');

  $r->any('/logout')->to('Admin#logout');
  $r->any('/*any' => {any => ''})->to('Pins#map')->name('map');
  # end-sample
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

