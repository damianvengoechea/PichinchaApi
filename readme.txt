===============================================================================
 PRUEBAS DE SERVICIOS REST - PETSTORE (https://petstore.swagger.io/)
 Karate DSL 1.5.1 + JUnit 5 + Gradle
===============================================================================

1. DESCRIPCIÓN
--------------
Pruebas automatizadas del API REST "PetStore" (Swagger, versión v2) que cubren:
  1. Añadir una mascota a la tienda                      (POST /pet)
  2. Consultar la mascota ingresada previamente por ID   (GET  /pet/{petId})
  3. Actualizar el nombre de la mascota y su estatus a "sold" (PUT /pet)
Adicionalmente se incluye un caso negativo:
  4. Consultar una mascota inexistente devuelve 404      (GET  /pet/{petId})

URL base del API: https://petstore.swagger.io/v2


2. PRERREQUISITOS
-----------------
  - JDK 17 o superior (probado con OpenJDK 27). Variable JAVA_HOME configurada.
  - Conexión a internet (para el API y la descarga de dependencias).
  - NO es necesario instalar Gradle ni Karate: se usa el wrapper incluido
    (gradlew), que descarga Gradle y las dependencias automáticamente.


3. EJECUCIÓN PASO A PASO
------------------------
  1) Clonar el repositorio:
       git clone <URL_DEL_REPOSITORIO>
       cd PruebaPichinchaKarate

  2) Ejecutar todas las pruebas:
       Windows (PowerShell / CMD):  gradlew.bat clean test
       Linux / macOS / Git Bash:    ./gradlew clean test

  3) (Opcional) Ejecutar un solo caso por su tag:
       gradlew.bat clean test "-Dkarate.options=--tags @AgregarMascota"
       gradlew.bat clean test "-Dkarate.options=--tags @ConsultarMascota"
       gradlew.bat clean test "-Dkarate.options=--tags @ActualizarMascota"
       gradlew.bat clean test "-Dkarate.options=--tags @ConsultarMascotaInexistente"

  4) (Opcional) Seleccionar el ambiente (ver karate-config.js):
       gradlew.bat clean test -Dkarate.env=qa
     Ambientes: default/qa -> https://petstore.swagger.io/v2
                local      -> http://localhost:8080/api/v3
                              (docker run -d -p 8080:8080 swaggerapi/petstore)

  5) Revisar los resultados (ver sección 5).

  Desde IntelliJ IDEA también se puede ejecutar la clase
  src/test/java/co/com/pichincha/petstore/PetstoreRunner.java (JDK 17+).


4. ESTRUCTURA DEL PROYECTO
--------------------------
  build.gradle.kts ............ Dependencias (Karate, JUnit 5) y tarea copiarReportes
  src/test/java/co/com/pichincha/petstore/
    PetstoreRunner.java ....... Runner JUnit 5: ejecuta los features (excluye @ignore)
                                y falla el build si algún escenario falla
  src/test/resources/
    karate-config.js .......... Variables globales: baseUrl por ambiente,
                                generarId(), timeouts, reintentos, headers
    logback-test.xml .......... Log DEBUG con cada petición/respuesta HTTP
    petstore/mascota/
      mascota.feature ......... Escenarios de prueba (casos 1 a 4)
      crear-mascota.feature ... Feature reutilizable (@ignore) que crea la mascota
                                como precondición de los casos 2 y 3
    petstore/data/mascota.json  Plantilla del cuerpo de la petición (entrada)
    petstore/schemas/mascota-schema.json  Esquema esperado de la respuesta
  reportes/ ................... Evidencia de la última ejecución (ver sección 5)
  readme.txt / conclusiones.txt


5. REPORTES Y EVIDENCIAS
------------------------
  Al terminar "gradlew test" la tarea copiarReportes copia automáticamente los
  resultados a la carpeta versionada reportes/ (también si alguna prueba falla):

  - reportes/karate-reports/karate-summary.html
        Reporte HTML de Karate. Abrirlo en el navegador; al entrar al feature
        se ve, paso a paso, cada petición y respuesta (headers y cuerpo),
        los "print" de entradas/salidas y el tiempo de respuesta.
  - reportes/karate-reports/karate-timeline.html   Línea de tiempo de ejecución.
  - reportes/karate-reports/petstore.mascota.mascota.json   Formato Cucumber JSON.
  - reportes/karate-reports/petstore.mascota.mascota.xml    Formato JUnit XML (CI).
  - reportes/karate.log
        Log completo con la traza HTTP (método, URL, headers, cuerpo,
        código de estado y tiempo de respuesta en ms) de cada llamada.

  Los reportes originales quedan también en build/karate-reports y build/karate.log.


6. VARIABLES DE CONFIGURACIÓN (karate-config.js)
------------------------------------------------
  baseUrl ......... URL base del API según karate.env
  generarId() ..... Genera un id aleatorio de 10 dígitos por escenario, para no
                    chocar con datos de otros usuarios del API público
  retry ........... 5 reintentos cada 1000 ms (consultas GET, ver conclusiones)
  connectTimeout .. 10000 ms   |   readTimeout .. 15000 ms
  headers ......... Accept: application/json


7. CASOS DE PRUEBA: ENTRADAS, SALIDAS Y VALIDACIONES
----------------------------------------------------
Variables comunes (Background de mascota.feature):
  id     = generarId()   (ej. 1556693872)
  nombre = 'Firulais'
  estado = 'available'

Cuerpo de entrada (plantilla data/mascota.json, con id/nombre/estado inyectados):
  {
    "id": <id>,
    "category": { "id": 1, "name": "Perros" },
    "name": "Firulais",
    "photoUrls": [ "https://images.dog.ceo/breeds/labrador/n02099712_100.jpg" ],
    "tags": [ { "id": 1, "name": "vacunado" } ],
    "status": "available"
  }

CASO 1 - Añadir una mascota a la tienda                         @AgregarMascota
  Petición : POST https://petstore.swagger.io/v2/pet
             Content-Type: application/json, cuerpo = plantilla anterior
  Salida   : HTTP 200, cuerpo JSON con la mascota creada
  Validaciones:
    - status 200 y Content-Type contiene application/json
    - la respuesta cumple el esquema (schemas/mascota-schema.json)
    - cada tag tiene { id: número, name: texto }
    - la respuesta es igual al cuerpo enviado (id, name='Firulais',
      status='available', categoría, fotos y tags)

CASO 2 - Consultar la mascota ingresada previamente (por ID)   @ConsultarMascota
  Precondición: se crea la mascota llamando a crear-mascota.feature
                (POST /pet, valida 200 y respuesta == cuerpo enviado)
  Petición : GET https://petstore.swagger.io/v2/pet/{id}
  Salida   : HTTP 200, cuerpo JSON con la mascota consultada
  Validaciones:
    - status 200 (con reintento hasta 200, ver conclusiones)
    - la respuesta cumple el esquema
    - la respuesta es idéntica a la mascota ingresada en la precondición
    - id, name='Firulais' y status='available'

CASO 3 - Actualizar nombre y estatus a "sold"                   @ActualizarMascota
  Precondición: se crea la mascota con crear-mascota.feature
  Variables   : nuevoNombre = 'Firulais Vendido', nuevoEstado = 'sold'
  Petición 1  : PUT https://petstore.swagger.io/v2/pet
                cuerpo = mascota creada con name='Firulais Vendido' y status='sold'
  Salida 1    : HTTP 200, cuerpo JSON con la mascota actualizada
  Validaciones:
    - status 200, cumple el esquema y la respuesta == cuerpo enviado
    - mismo id, name='Firulais Vendido', status='sold'
  Petición 2  : GET https://petstore.swagger.io/v2/pet/{id}  (verificación)
  Salida 2    : HTTP 200 con name='Firulais Vendido' y status='sold'
                (confirma que el cambio quedó persistido)

CASO 4 (adicional) - Consultar mascota inexistente   @ConsultarMascotaInexistente
  Petición : GET https://petstore.swagger.io/v2/pet/{id + 1}
  Salida   : HTTP 404, { "code": 1, "type": "error", "message": "Pet not found" }


8. RESULTADO DE LA ÚLTIMA EJECUCIÓN
-----------------------------------
  scenarios: 4 | passed: 4 | failed: 0   (BUILD SUCCESSFUL)
  Tiempos de respuesta observados: entre ~360 ms y ~860 ms por petición.
  Detalle en reportes/karate-reports/karate-summary.html
