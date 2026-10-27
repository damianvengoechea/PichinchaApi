plugins {
    java
}

group = "co.com.pichincha"
version = "1.0-SNAPSHOT"

val karateVersion = "1.5.1"
val junitVersion = "5.11.4"

repositories {
    mavenCentral()
}

dependencies {
    // Karate DSL + JUnit 5
    testImplementation("io.karatelabs:karate-junit5:$karateVersion")
    testImplementation(platform("org.junit:junit-bom:$junitVersion"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release = 17
}

tasks.test {
    useJUnitPlatform()

    // Propaga las propiedades de ejecución, ej: gradlew test -Dkarate.env=qa -Dkarate.options="--tags @AgregarMascota"
    listOf("karate.env", "karate.options").forEach { key ->
        System.getProperty(key)?.let { systemProperty(key, it) }
    }

    // Las pruebas consumen un servicio externo: siempre se ejecutan, aunque el código no cambie
    outputs.upToDateWhen { false }

    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = true
    }

    // Copia los reportes a la carpeta versionada reportes/ aunque fallen pruebas
    finalizedBy("copiarReportes")
}

tasks.register<Sync>("copiarReportes") {
    description = "Copia el reporte HTML de Karate y el log HTTP a la carpeta reportes/"
    from(layout.buildDirectory.dir("karate-reports")) { into("karate-reports") }
    from(layout.buildDirectory.file("karate.log"))
    into(layout.projectDirectory.dir("reportes"))
}
