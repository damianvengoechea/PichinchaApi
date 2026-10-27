function fn() {
  var env = karate.env || 'default';
  karate.log('Ambiente de ejecución (karate.env):', env);

  var config = {
    env: env,
    baseUrl: 'https://petstore.swagger.io/v2'
  };

  if (env == 'qa') {
    config.baseUrl = 'https://petstore.swagger.io/v2';
  } else if (env == 'local') {
    // Imagen oficial: docker run -d -p 8080:8080 swaggerapi/petstore
    config.baseUrl = 'http://localhost:8080/api/v3';
  }

  // Genera un id aleatorio de 10 dígitos dentro del rango int (< 2^31): los valores mayores se
  // tratan como double y Karate los escribe en notación científica en la URL (ej. /pet/1.79E14)
  config.generarId = function () {
    return 1000000000 + Math.floor(Math.random() * 1000000000);
  };

  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 15000);
  // La API pública está detrás de un balanceador: se reintenta la consulta si la réplica aún no tiene el dato
  karate.configure('retry', { count: 5, interval: 1000 });
  karate.configure('headers', { Accept: 'application/json' });

  return config;
}
