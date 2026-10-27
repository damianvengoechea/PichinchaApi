package co.com.pichincha.petstore;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PetstoreRunner {

    @Test
    void ejecutarPruebasPetstore() {
        Results resultados = Runner.path("classpath:petstore")
                .tags("~@ignore")
                .outputJunitXml(true)
                .outputCucumberJson(true)
                .parallel(1);
        assertEquals(0, resultados.getFailCount(), resultados.getErrorMessages());
    }
}
