@ignore
Feature: Reutilizable - crea una mascota en la tienda

  # Entradas: id, nombre, estado
  # Salidas: response (mascota creada), mascota (cuerpo enviado)
  Scenario: Crear mascota
    * url baseUrl
    * def mascota = read('classpath:petstore/data/mascota.json')
    Given path 'pet'
    And request mascota
    When method post
    Then status 200
    And match response == mascota
