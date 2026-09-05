# Limitaciones y amenazas a la validez

## Corpus

La distribución de textos conservados no representa necesariamente la distribución de ideas de una época. Además, longitud, género, autoría y estilo pueden estar correlacionados con el periodo estudiado.

## Traducción

Una traducción puede sustituir términos, fusionar distinciones o introducir vocabulario propio de otra época. Registrar el traductor no elimina el sesgo; solo lo hace trazable.

## Edición y OCR

Modernización ortográfica, normalización editorial y errores OCR modifican frecuencias y contextos. Los checksums garantizan reproducibilidad del archivo usado, no fidelidad filológica.

## Polisemia

PPMI-SVD produce un vector estático por token. Si una palabra tiene varios sentidos, el vector mezcla sus contextos. Para conceptos polisémicos importantes se recomienda una extensión futura con embeddings contextuales por ocurrencia y clustering de sentidos.

## Conceptos

Los aliases multiword se detectan exactamente para frecuencia y contexto. En el embedding estático de v0.2.0, su representación se aproxima a partir de los tokens componentes; para conceptos donde la frase sea semánticamente indivisible conviene añadir un backend de phrase embeddings o precomposición validada.

La lista de aliases es una decisión teórica. No existe una ontología neutral de conceptos morales o filosóficos. Los resultados deben acompañarse de una justificación de esa operacionalización.

## Frecuencia

La frecuencia condiciona la calidad de las representaciones. El baseline de controles por frecuencia ayuda, pero no elimina toda relación entre frecuencia, ruido y desplazamiento.

## Valencia

El lexicón incluido es ilustrativo. La polaridad de una palabra depende de contexto, dominio y época. No debe utilizarse como medida universal de moralidad.

## Embeddings

La similitud distribucional refleja patrones de contexto textual. Dos términos próximos vectorialmente no tienen por qué ser filosóficamente equivalentes.

## Alineamiento

Procrustes presupone que existe un subconjunto suficientemente estable de anclas compartidas. Si casi todo el vocabulario cambia o los corpus son demasiado distintos, esa hipótesis puede fallar.

## Inferencia histórica

El pipeline puede detectar patrones cuantitativos. No demuestra que una tradición haya causado cambios en otra ni que un autor sostenga una tesis concreta. Las conclusiones fuertes necesitan lectura cualitativa y evidencia histórica independiente.


## Fronteras y bootstrap

ETHOS preserva las fronteras entre documentos. El bootstrap por bloques también conserva cada bloque remuestreado como secuencia independiente para no inventar contextos; como contrapartida, las dependencias que atraviesan el límite artificial de un bloque no se conservan dentro de esa réplica. El tamaño de bloque debe incluirse en los análisis de sensibilidad de estudios finales.
