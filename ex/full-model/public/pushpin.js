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

