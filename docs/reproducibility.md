# Reproducibilidad

## Entorno

La compatibilidad mínima declarada es Julia 1.10. La CI prueba Julia 1.10 y 1.12.

La versión base solo utiliza bibliotecas estándar. Aun así, para una release científica se recomienda conservar el `Manifest.toml` generado por la versión exacta de Julia usada.

`results/run_metadata.toml` registra además la versión de ETHOS, Julia, sistema operativo, arquitectura, número de threads, proveedor BLAS y el commit Git cuando la ejecución ocurre dentro de un repositorio Git.

## Datos

Cada documento puede exigir un SHA-256 en `config/corpora.toml`. El pipeline recalcula el hash antes del análisis y guarda los hashes reales en `results/run_metadata.toml`.

## Aleatoriedad

El único componente aleatorio de la versión base es el bootstrap. El remuestreo respeta fronteras documentales: los bloques seleccionados nunca se concatenan para formar contextos sintéticos. Se utiliza `MersenneTwister` con seeds derivadas de `random_seed`, el grupo, el par de periodos y el concepto.

## Resultados

`results/` se considera derivado y no se versiona por defecto. En una publicación, archiva una copia inmutable de:

- tag del código;
- configuración;
- corpus o identificadores/checksums cuando no sea redistribuible;
- versión de Julia y Manifest;
- tablas y figuras finales;
- informe generado.

## Repetición

```bash
julia --project=. scripts/validate_corpus.jl
julia --project=. scripts/run_pipeline.jl
```

Si los archivos, configuración y versión de Julia permanecen iguales, los resultados deterministas deben coincidir y el bootstrap debe reproducirse por seed.
