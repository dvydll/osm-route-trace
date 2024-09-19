#!/bin/bash

# Descargar la imagen de OSRM
docker pull osrm/osrm-backend

# Descargar el archivo OSM para España desde Geofabrik
wget http://download.geofabrik.de/europe/spain-latest.osm.pbf

# Extraer los datos de OSM con OSRM: Extrae los datos del archivo OSM usando el perfil de conducción (car.lua)
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-extract -p /opt/car.lua /data/spain-latest.osm.pbf

# Particionar los datos: Este paso optimiza la velocidad de cálculo de rutas en grandes regiones como España
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-partition /data/spain-latest.osrm

# Personalizar los datos: Este paso personaliza los datos para mejorar el rendimiento de enrutamiento
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-customize /data/spain-latest.osrm

# Levantar el servidor OSRM
docker run -t -i -p 5000:5000 -v "${PWD}:/data" osrm/osrm-backend osrm-routed --algorithm mld /data/spain-latest.osrm

# Puerto 5000: El servidor estará levantado en el puerto 5000 de tu máquina.
# Región específica: Si quieres un área más pequeña (como Madrid o Cataluña), puedes descargar un archivo OSM específico desde Geofabrik, que tiene subdivisiones regionales.
# Con esto podrás ejecutar OSRM utilizando los datos de España y hacer consultas de rutas entre dos puntos geográficos en tu propio servidor local.