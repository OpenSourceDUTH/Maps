# OpenSourceDUTH Maps (Info Dump Branch)
This branch will be temporarily used as a place to dump everything until a preliminary version of the map is stablished and ready to be pushed to main.

## Basic Info About Maps
An e-map is basically a database of geographic data where you try to input every object from the real world. A rough exmplanation of how e-maps work is that you haave a tile server which serves mostly raster or vector **data** (more on that later), and a client library (i.e. martin, openmaptiles etc) that takes the raw data and outputs it on the browser in a human readable way. Basically, it's just a visually rendered database. 

## Raster vs Vector
In computer graphics and digital photography, a raster graphic, raster image, or simply raster is a digital image made up of a rectangular grid of tiny colored (usually square) so-called pixels. Unlike vector graphics which use mathematical formulas to describe shapes and lines, raster images store the exact color of each pixel, making them ideal for photographs and images with complex colors and details [[1].](https://en.wikipedia.org/wiki/Raster_graphics) In our case we know that raster tiles are usually prerendered images at different zoom levels created from the database, their main attributes are that they are easy to serve and load easily on the client but they take more space on the server and are more network heavy. Vector tiles are being generated on the client and usually take less space, require less traffic but use more compute in order to render. E-maps started from raster tiles (which also have static elements and don't have interactive elements) and slowly evolved to vector tiles with some filetypes combining both raster and vector data on the same tile.

## Quick Intro into this projec
OpenSourceDUTH Maps, tries to use layered vector data to display the campus and (although it has not been implemented yet) we will use either a database or a geojson type for the points and roads so we can edit them with live data and parameters that are not part of the usual OSM specification. We utilize the *Martin* tile server to serve both our geojson, tile and style data, we then send that data to our frontend renderer (maplibre) and display them with simple html,css,js. Ultimately, styled maps will be send through our API and we will integrate live data and integrate with Universis.

Some preliminary features include:
- Three Base layer tiles: Vector, Aerial and 3D imagery
- Custom navigation (this needs to be an API endpoint/SDK)
- Integration with our own and 3rd party APIs for usage such as, displaying the food schedule on the map, showing current lectured happening in classes so you know which one is empty, wather data, bus arrivals etc...


```
+---------------------------------+                                                    
|                                 |                                                    
|                                 |                                                    
|         Martin Server           |                                                    
|                                 |                                                    
|                                 |                                                    
+---------------------------------+                    +------------------------------+
                |                                      |                              |
                |                                      |                              |
                | Map Data (Blank Tiles)     +-------->|         Client Map           |
                |                            |         |                              |
                v                            |         |                              |
+---------------------------------+          |         +------------------------------+
|                                 |          |                                         
|                                 |          |                                         
|           Style.json            |----------+                                         
|                                 |                                                    
|                                 |                                                    
+---------------------------------+                                                    
```

## Three-Tier Navigation System
A simple rundown of how a navigation system works and how we implement it for the uninitiated.

In order to achieve complex routing we need to completely separate the map rendering into layers and at the same time compute the calculations for the navigation path server side. If we want to make a mobile SDK in the future we could create a fallback mechanism for offline navigation, since mobile mapping SDKs (I like to call them MMSDK) can cache map sections in the app's cache which is more than enough to store the vector version of the campus (~4kb). So, for the routing we need the *Client*, the *API Server* (we can use our Go API for that `/v[X]/maps/routing` or something) and the *Routing Engine* which we will **not build** because it's a very big project and the math are a pain. The *Client* will send the request and recieve a GeoJSON response to be displayed on the map, the *API Server* will recieve the request from the client (Return 418 - I am a teapot /joke), call the routing engine and return the results to the client and finally the *Routing Engine* itself which stores all the data (OSM, Elevation, Step Count etc), run the A* algorithm and apply the custom weights. 

*Note: The Roouting Engine will be Valhalla because it's written in the language of GOD (C++) and is wicked fast... MIT License BTW* </br>
*[You can try a demo in Thessalonki which has good OSM mapping](https://valhalla.github.io/demos/routing/#loc=15,40.640677,22.949710)*

### Paper Version Implementation
We ingest the OpenStreetMap (OSM) and [Digital Elevation Model (DEM)](https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3) data to the *Routing Engine*. We configure it to use this data and build it's internal network graph which enhances the data accurate with the data (such as the elevation change \$\Delta\$). Then we can apply our custom cost for the A* weights, which I propose to be something like: \$C_{\text{total}} = w_{\text{time}} \cdot t + w_{\text{distance}} \cdot d + w_{\text{elevation}} \cdot \Delta h + \dots\$ through [*Valhalla's Costing Model*](https://valhalla.github.io/valhalla/sif/elevation_costing/#adding-grade-factors-to-dynamic-costing).

For the API we need to create an endpoint (`*/v[X]/maps/routing)` that accets a `POST` request (we could do a `GET` request and easily cache data but I don't think it's necessary plus we might have issues with the request length) along with parameters such as `nodes`, `elevation_weight`, `route_type` and things like `accessibility_scale`. Then we HTTP Request the *routing engine* with a JSON payload, process it in the routing engine, engrich the data with information like written instructions ([see Google's solution to unnamed road navigation in India](https://webdesignerdepot.com/mapping-india-how-google-designed-a-user-centric-navigation-experience/)) and return the calculated route as a `LineString`. Finally, we render it as a layer on the map.

## Running The Project
Clone the project (First open a terminal)
```bash
git clone https://github.com/OpenSourceDUTH/Maps
```
Navigate into the project directory
```bash
cd ./Maps/
```
Start the python http server so the HTML file can fetch the external ones. (http://localhost:8000)
```bash
python -m http.server
```
<details>
  <summary>Windows Instructions</summary>
  Download linux :P
  (or at least WSL)
</details>

[1] https://en.wikipedia.org/wiki/Raster_graphics
