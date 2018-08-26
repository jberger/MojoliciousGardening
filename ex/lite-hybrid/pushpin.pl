use Mojolicious::Lite -signatures;

use Mojo::SQLite;

my $app = app;

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
  my $pw = $c->req->url->to_abs->password;
  return $c->session(admin => 1) if $pw eq $config->{admin};
  return $c->basic_auth;
});

$admin->get('/' => 'table');

$admin->delete('/:id' => sub ($c) {
  $c->db->delete(pins => { id => $c->param('id') });
  $c->redirect_to('table');
} => 'remove');

$r->any('/logout' => sub ($c) { $c->session(expires => 1)->basic_auth });

$r->any('/*any' => {any => ''} => 'map');

app->start;

__DATA__

@@ pushpin.js
import * as L from 'https://unpkg.com/leaflet@1.3.4/dist/leaflet-src.esm.js';

let pins = [];
let map;

export function initMap() {
  map = L.map('mapid');
  map.doubleClickZoom.disable();
  let osmUrl='https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  let osmAttrib='Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
  let osm = new L.TileLayer(osmUrl, {minZoom: 1, maxZoom: 18, attribution: osmAttrib});

  map.setView(new L.LatLng(59.9238, 10.7317), 12);
  map.addLayer(osm);

  map.on('dblclick', async function(e) {
    let text = window.prompt('Would you like to add this pin? ' + e.latlng.toString() + ' Optional text may be added below.');
    if (text == null) return;
    await fetch('/pins', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8'},
      body: JSON.stringify({
        lat: e.latlng.lat,
        lng: e.latlng.lng,
        text,
      }),
    });
    getPins();
  });

  getPins();
}

export async function getPins() {
  removePins();
  let res  = await fetch('/pins');
  let data = await res.json();
  let points = [];
  data.forEach(item => {
    let point = L.latLng(item.lat, item.lng);
    points.push(point);
    let pin = L.marker(point).addTo(map);
    if (item.text) pin.bindPopup(item.text);
    pins.push(pin);
  });
  map.fitBounds(L.latLngBounds(points), {maxZoom: 12});
}

export function removePins() {
  pins.forEach(pin => pin.remove());
}

@@ map.html.ep
% layout 'main';

% content_for head => begin
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.4/dist/leaflet.css" integrity="sha512-puBpdR0798OZvTTbP4A8Ix/l+A4dHDD0DGqYW6RQ+9jxkRFclaxxQb/SJAWZfWAkuyeQUytO7+7N4QKrDh+drA==" crossorigin=""/>
% end

<div id="mapid" style="width: 800px; height: 600px;"></div>
<script type="module">
  import { initMap } from './pushpin.js';
  initMap();
</script>

@@ table.html.ep
% layout 'main';

<table>
  % for my $pin (all_pins->each) {
  <tr>
    %= t td => $pin->{lat}
    %= t td => $pin->{lng}
    %= t td => $pin->{text}
    <td>
    %= form_for remove => {id => $pin->{id}} => begin
      %= submit_button 'remove'
    % end
    </td>
  </tr>
  % }
</table>

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>MojoConf Pushpin</title>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  %= content_for 'head'
</head>
<body><%= content %></body>
</html>

@@ migrations
-- 1 up
create table pins (
  id integer primary key,
  lat real,
  lng real,
  text text
);

