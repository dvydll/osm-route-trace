# Trazado de rutas con OpenStreetMap

## Setup Docker OSRM

### Requisitos previos

Antes de comenzar, asegúrate de cumplir con los siguientes requisitos:

1. **_Docker_:** _Docker_ debe estar instalado y en ejecución en tu sistema. Si no tienes _Docker_ instalado, puedes descargarlo e instalarlo desde la [página oficial de _Docker_](https://www.docker.com/).

2. **Conexión a Internet:** Necesitarás conexión para descargar la imagen de Docker de **OSRM** y el archivo de datos _OSM_.

3. **Espacio en disco:** Dependiendo del tamaño de los datos que quieras procesar (en este caso, España completa), necesitarás suficiente espacio en disco para almacenar tanto el archivo _OSM_ como los datos procesados por **OSRM**.

4. **Script de instalación:** Asegúrate de tener el archivo osrm_setup.sh guardado en tu máquina. Este script contiene los pasos necesarios para configurar **OSRM** con los datos de OpenStreetMap.

### Contenido del script `osrm_setup.sh`

El script contiene los siguientes pasos:

```bash
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
```

### Preparar el script

1. **Descargar el script:** Asegúrate de que el archivo osrm_setup.sh esté en el directorio donde deseas configurar **OSRM**.

2. **Dar permisos de ejecución al script:** Antes de ejecutar el script, necesitas darle permisos de ejecución. Puedes hacerlo con el siguiente comando:

```bash
chmod +x ./osrm_setup.sh
```

### Ejecutar el script

Una vez que hayas configurado los permisos de ejecución, puedes ejecutar el script con el siguiente comando:

```bash
./osrm_setup.sh
```

Este script ejecutará todos los pasos necesarios para:

1. Descargar la imagen de _Docker_ para **OSRM**.
2. Descargar los datos de _OpenStreetMap_ para España.
3. Procesar esos datos para su uso en **OSRM**.
4. Levantar un servidor local de **OSRM** en el puerto 5000 que puedes utilizar para consultar rutas entre puntos geográficos.

### Consultar rutas

Una vez que el servidor **OSRM** esté en ejecución, puedes hacer consultas de rutas entre puntos geográficos utilizando solicitudes _HTTP_ a la _API_ de **OSRM**. El servidor estará disponible en `http://localhost:5000`

Puedes hacer una solicitud de ejemplo para obtener la ruta entre dos coordenadas de la siguiente manera:

```bash
curl "http://localhost:5000/route/v1/driving/-3.70379,40.41678;-0.37564,39.46975?overview=false"
```

En este ejemplo, se solicitan direcciones de conducción desde _Madrid_ (-3.70379, 40.41678) hasta _Valencia_ (-0.37564, 39.46975).

### Optimización y datos regionales
Si prefieres trabajar con una región más pequeña (por ejemplo, _Madrid_ o _Cataluña_), puedes descargar archivos de datos más específicos desde **_Geofabrik_**. Solo necesitas reemplazar el enlace de descarga del archivo _OSM_ en el script por el de la región que prefieras.

---

## Algoritmos disponibles en OSRM

### MLD (<span style="color: lightgreen;">Multi-Level Dijkstra</span>) `--algorithm mld`

#### Descripción

Es el algoritmo por defecto para grandes áreas, como países enteros. Este algoritmo divide el grafo de carreteras en niveles jerárquicos (zonas o "cells"), lo que acelera el cálculo de rutas en grandes mapas. Utiliza particionamiento y personalización de los datos, lo que permite rutas rápidas en áreas grandes.

#### Usos

Es ideal para grandes regiones y permite realizar rutas rápidas después de un preprocesamiento más largo.

> #### Pasos requeridos
>
> - `osrm-partition`
> - `osrm-customize`

#### Ventajas

- Buen equilibrio entre tiempo de procesamiento y tiempo de cálculo de rutas.
- Acelera las consultas en mapas muy grandes como países.

---

### CH (<span style="color: lightgreen;">Contraction Hierarchies</span>) `--algorithm ch`

#### Descripción

El algoritmo de Contraction Hierarchies (CH) es otro método común en OSRM para encontrar rutas rápidamente. Este algoritmo funciona mejor en áreas más pequeñas o cuando el preprocesamiento es menos importante. Se enfoca en simplificar el grafo de carreteras antes de calcular rutas, eliminando nodos y creando un grafo jerárquico.

#### Usos

Se usa cuando las consultas de ruta deben ser extremadamente rápidas y el tiempo de preprocesamiento no es un problema.

> #### Pasos requeridos
>
> - `osrm-contract`

#### Ventajas

- Muy rápido en el cálculo de rutas después del preprocesamiento.
- Adecuado para aplicaciones donde la velocidad de consulta es crucial.

#### Desventajas

- No soporta perfiles dinámicos (no es posible cambiar la lógica de enrutamiento sin volver a procesar todo).

---

### CoreCH (<span style="color: lightgreen;">Core-Based Contraction Hierarchies</span>) `--algorithm corech` <small style="color: tomato;">(experimental)</small>

#### Descripción

Es una variante del algoritmo CH, optimizado para ciertos casos. Combina ideas de CH y MLD para mejorar el rendimiento en mapas grandes.

#### Usos

Es experimental y no siempre se utiliza, pero podría ser útil en algunos casos en mapas grandes.

---

### Comparación de Algoritmos

| Algoritmo |   Preprocesamiento   | Velocidad de consulta |       Casos de uso típicos       |
| :-------: | :------------------: | :-------------------: | :------------------------------: |
|    MLD    | Alto (con partición) |      Muy rápida       |   Grandes áreas (como países)    |
|    CH     | Alto (con contract)  | Extremadamente rápida |    Áreas pequeñas o medianas     |
|  CoreCH   |     Experimental     |      Intermedio       | Mapas grandes, pero experimental |

#### Ejemplo de uso:

Si quisieras usar el algoritmo CH en lugar de MLD, cambiarías la línea de comandos cuando levantas el servidor:

```bash
docker run -t -i -p 5000:5000 -v "${PWD}:/data" osrm/osrm-backend osrm-routed --algorithm ch /data/spain-latest.osrm
```

Para usar CH, debes _reemplazar_ los comandos de preprocesamiento `osrm-partition` y `osrm-customize` por el comando de CH:

```bash
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-contract /data/spain-latest.osrm
```

### Conclusión

- **_MLD_**: Es el más común y recomendable para grandes áreas como países. Ofrece consultas rápidas después de un largo proceso de particionamiento y personalización.
- **_CH_**: Mejor para áreas más pequeñas o cuando las consultas rápidas son una prioridad, pero requiere un tiempo de preprocesamiento considerable.
- **_CoreCH_**: Experimental y no muy utilizado en producción.
