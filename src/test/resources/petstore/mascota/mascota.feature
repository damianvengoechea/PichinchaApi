@Petstore
Feature: Gestión de mascotas en la PetStore (https://petstore.swagger.io)
  Como administrador de la tienda de mascotas
  Quiero registrar, consultar y actualizar mascotas mediante el API REST
  Para mantener actualizado el inventario de la tienda

  Background:
    * url baseUrl
    * def esquemaMascota = read('classpath:petstore/schemas/mascota-schema.json')
    # Variables de entrada comunes: id único por escenario para no chocar con datos de otros usuarios del API público
    * def id = generarId()
    * def nombre = 'Firulais'
    * def estado = 'available'

  @AgregarMascota
  Scenario: Añadir una mascota a la tienda
    # Entrada: cuerpo JSON construido desde la plantilla data/mascota.json
    * def mascota = read('classpath:petstore/data/mascota.json')
    * print 'Entrada - mascota a crear:', mascota
    Given path 'pet'
    And request mascota
    When method post
    Then status 200
    And match header Content-Type contains 'application/json'
    And match response == esquemaMascota
    And match each response.tags == { id: '#number', name: '#string' }
    And match response == mascota
    And match response.id == id
    And match response.name == nombre
    And match response.status == 'available'
    * print 'Salida - mascota creada:', response
    * print 'Tiempo de respuesta (ms):', responseTime

  @ConsultarMascota
  Scenario: Consultar la mascota ingresada previamente (búsqueda por ID)
    # Precondición: se ingresa la mascota con el feature reutilizable
    * def creacion = call read('crear-mascota.feature') { id: '#(id)', nombre: '#(nombre)', estado: '#(estado)' }
    * def mascotaIngresada = creacion.response
    * print 'Entrada - id a consultar:', id
    Given path 'pet', id
    And retry until responseStatus == 200
    When method get
    Then status 200
    And match response == esquemaMascota
    And match response == mascotaIngresada
    And match response.id == id
    And match response.name == nombre
    And match response.status == 'available'
    * print 'Salida - mascota consultada:', response
    * print 'Tiempo de respuesta (ms):', responseTime

  @ActualizarMascota
  Scenario: Actualizar el nombre de la mascota y el estatus a "sold"
    # Precondición: se ingresa la mascota con el feature reutilizable
    * def creacion = call read('crear-mascota.feature') { id: '#(id)', nombre: '#(nombre)', estado: '#(estado)' }
    * def nuevoNombre = 'Firulais Vendido'
    * def nuevoEstado = 'sold'
    * def mascotaActualizada = creacion.response
    * set mascotaActualizada.name = nuevoNombre
    * set mascotaActualizada.status = nuevoEstado
    * print 'Entrada - mascota con datos actualizados:', mascotaActualizada
    Given path 'pet'
    And request mascotaActualizada
    When method put
    Then status 200
    And match response == esquemaMascota
    And match response == mascotaActualizada
    And match response.id == id
    And match response.name == nuevoNombre
    And match response.status == 'sold'
    * print 'Salida - mascota actualizada:', response

    # Verificación: la consulta por ID refleja el cambio
    Given path 'pet', id
    And retry until responseStatus == 200 && response.status == 'sold'
    When method get
    Then status 200
    And match response.name == nuevoNombre
    And match response.status == 'sold'
    * print 'Salida - consulta posterior a la actualización:', response

  @ConsultarMascotaInexistente
  Scenario: Consultar una mascota que no existe devuelve 404
    * def idInexistente = id + 1
    * print 'Entrada - id inexistente:', idInexistente
    Given path 'pet', idInexistente
    When method get
    Then status 404
    And match response == { code: 1, type: 'error', message: 'Pet not found' }
    * print 'Salida - error:', response
