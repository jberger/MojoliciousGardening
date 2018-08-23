use Mojolicious::Lite -signatures;

use Mojo::SQLite;

helper 'sqlite' => sub {
  state $sqlite = Mojo::SQLite->new('pushpin.db')->auto_migrate(1)->tap(sub{ $_->migrations->from_data });
};

any '/' => 'map';

get '/pins' => sub ($c) {
  $c->render(json => $c->sqlite->db->select('pins')->hashes);
};

post '/pins' => sub ($c) {
  $c->sqlite->db->insert(pins => $c->req->json);
  $c->rendered(204);
};

app->start;

__DATA__

@@ pushpin.js

var pins = [];
var map;

export function initMap() {
  map = L.map('mapid');
  map.doubleClickZoom.disable();
  var osmUrl='https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  var osmAttrib='Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
  var osm = new L.TileLayer(osmUrl, {minZoom: 1, maxZoom: 18, attribution: osmAttrib});

  map.setView(new L.LatLng(59.9238, 10.7317), 12);
  map.addLayer(osm);

  map.on('dblclick', function(e) {
    var text = window.prompt('Would you like to add this pin? ' + e.latlng.toString() + ' Optional text may be added below.');
    if (text == null) return;
    fetch('/pins', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8'},
      body: JSON.stringify({
        lat: e.latlng.lat,
        lng: e.latlng.lng,
        text: text,
      }),
    }).then(() => getPins());
  });

  getPins();
}

export function getPins() {
  removePins();
  fetch('/pins')
    .then(res => res.json())
    .then(data => {
      var points = [];
      data.forEach(item => {
        var point = L.latLng(item.lat, item.lng);
        points.push(point);
        var pin = L.marker(point).addTo(map);
        if (item.text) pin.bindPopup(item.text);
        pins.push(pin);
      });
      map.fitBounds(L.latLngBounds(points), {maxZoom: 12});
    });
}

export function removePins() {
  pins.forEach(pin => pin.remove());
}

@@ map.html.ep
% layout 'leaflet';

<div id="mapid" style="width: 800px; height: 600px;"></div>
<script type="module">
  import { initMap } from './pushpin.js';

  initMap();
</script>


@@ layouts/leaflet.html.ep
<!DOCTYPE html>
<html>
<head>

  <title>MojoConf Pushpin</title>

  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!--link rel="shortcut icon" type="image/x-icon" href="docs/images/favicon.ico" /-->

  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.4/dist/leaflet.css" integrity="sha512-puBpdR0798OZvTTbP4A8Ix/l+A4dHDD0DGqYW6RQ+9jxkRFclaxxQb/SJAWZfWAkuyeQUytO7+7N4QKrDh+drA==" crossorigin=""/>
  <script src="https://unpkg.com/leaflet@1.3.4/dist/leaflet.js" integrity="sha512-nMMmRyTVoLYqjP9hrbed9S+FzjZHW5gY1TWCHA5ckwXZBadntCNs8kEqAWdrb9O7rxbCaA4lKTIWjDXZxflOcA==" crossorigin=""></script>

</head>
<body>

%= content


</body>
</html>

@@ migrations
-- 1 up
create table pins (
  id integer primary key,
  lat real,
  lng real,
  text text
);

