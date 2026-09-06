# Metodología

## 1. Unidad de análisis

El proyecto distingue cuatro niveles:

1. **documento**, con metadatos de procedencia;
2. **token**, como observación textual;
3. **alias léxico**, que puede contener uno o varios tokens;
4. **concepto**, definido por un conjunto explícito de aliases.

Esta separación es necesaria porque la ausencia de una palabra no implica la ausencia del concepto correspondiente.

## 2. Preprocesamiento

La normalización base:

- convierte a minúsculas;
- normaliza apóstrofes y guiones tipográficos;
- elimina caracteres de control;
- colapsa espacios;
- preserva letras Unicode y signos diacríticos.

No se aplica stemming por defecto. Tampoco se eliminan stop-words globalmente. La política depende de la tarea:

- frecuencia conceptual: texto tokenizado completo;
- contexto y valencia: texto tokenizado completo;
- embeddings: texto tokenizado completo, sujeto a frecuencia mínima;
- DTM/TF-IDF: stop-words opcionales.

Esto evita destruir negaciones o estructura contextual necesaria para otros análisis.

## 3. Frecuencia

Para concepto `c`:

```math
f_c = \frac{n_c}{N}S
```

El valor por defecto `S = 10^6` produce apariciones por millón de tokens.

Los aliases se detectan como spans y se evita contar dos veces una expresión cuando un alias corto está contenido en otro más largo en la misma posición.

## 4. Fronteras documentales

Los documentos de un mismo grupo **no se concatenan semánticamente**. Todas las operaciones con ventanas locales reciben una colección de secuencias y procesan cada documento de forma independiente. Esto evita aliases multi-palabra, coocurrencias o contextos de valencia artificiales entre el final de una obra y el inicio de otra.

Las frecuencias de grupo suman recuentos por documento y normalizan por el total de tokens del grupo, sin permitir spans entre documentos.

## 5. Coocurrencia

Para cada token central se observa una ventana de radio `w`. Con ponderación por distancia:

```math
C_{ij} \leftarrow C_{ij} + \frac{1}{|p_i-p_j|}
```

La ponderación puede desactivarse desde configuración.

## 6. PPMI

A partir de la matriz `C`:

```math
PMI(i,j)=\log_2\frac{C_{ij}C_{**}}{C_{i*}C_{*j}}
```

```math
PPMI(i,j)=\max(PMI(i,j),0)
```

Las asociaciones PPMI sirven como baseline interpretable y también como entrada al embedding SVD.

## 7. Embedding PPMI-SVD

Se factoriza:

```math
M = U\Sigma V^T
```

y se retienen `k` componentes:

```math
E = U_k\Sigma_k^{1/2}
```

Este backend se eligió para la primera versión porque es determinista, auditable y no depende de paquetes externos. No se afirma que sea universalmente superior a SGNS, FastText o modelos contextuales.

## 8. Vector de concepto

Un concepto puede tener varios términos. El vector conceptual base es la media de los vectores disponibles de sus tokens configurados:

```math
v_c = \frac{1}{m}\sum_{i=1}^{m}v_{t_i}
```

Es una definición transparente, pero debe considerarse una aproximación. Para estudios de polisemia fuerte puede ser preferible pasar a representaciones contextuales por ocurrencia.

## 9. Alineamiento Procrustes

Los espacios entrenados independientemente tienen orientación arbitraria. Sean `A` y `B` matrices con los mismos términos ancla en dos corpus. Se busca:

```math
R^*=\arg\min_{R^TR=I}\|BR-A\|_F
```

Si:

```math
B^TA=U\Sigma V^T
```

entonces:

```math
R^*=UV^T
```

Los términos de los conceptos objetivo se excluyen del conjunto de anclas. Esto reduce la posibilidad de que el propio término cuya variación se mide determine su alineamiento. Además, al comparar un concepto entre dos corpus se utilizan únicamente aliases que puedan representarse en ambos espacios; así se evita construir el vector conceptual con conjuntos léxicos distintos en cada corpus.

## 10. Cambio semántico

Tras alinear el segundo espacio:

```math
D(c)=1-\frac{v_c^A\cdot v_c^B}{\|v_c^A\|\|v_c^B\|}
```

`D(c)` es un desplazamiento geométrico. Su interpretación histórica exige evidencia externa.

## 11. Bootstrap por bloques

El muestreo independiente de tokens rompería demasiado la estructura local del texto. El pipeline divide cada documento en bloques contiguos de tamaño configurable y remuestrea bloques con reemplazo. Cada bloque remuestreado permanece como una secuencia independiente; por tanto, el bootstrap no inventa vecindades entre bloques que no eran contiguos ni entre documentos distintos.

Para cada réplica de cambio semántico:

1. remuestrea bloques de ambos corpus;
2. reconstruye los embeddings;
3. busca anclas compartidas;
4. alinea mediante Procrustes;
5. recalcula el desplazamiento conceptual.

Los percentiles empíricos forman el intervalo de confianza.

El número de réplicas del corpus sintético está pensado para demostración. Para análisis finales debe aumentarse y comprobarse la estabilidad del intervalo.

## 12. Controles de frecuencia

Las representaciones distribucionales pueden presentar cambios aparentes asociados a frecuencia. Para cada concepto se calcula una escala de frecuencia aproximadamente geométrica entre corpus y se seleccionan términos compartidos con frecuencia dentro de un factor configurable.

Para esos términos se calcula el mismo desplazamiento. El pipeline exporta:

```math
z_c=\frac{D(c)-\mu_{control}}{\sigma_{control}}
```

El control es descriptivo: detecta un resultado que no destaca frente a términos de frecuencia similar, pero no convierte el estudio en causal.

## 13. Valencia contextual

Cada span conceptual define una ventana local. Los tokens presentes en el lexicón aportan puntuaciones y una negación cercana invierte el signo.

La media resultante se denomina **valencia contextual estimada**. El lexicón debe adaptarse al idioma, época y dominio. Para textos históricos, un lexicón moderno puede introducir sesgo.

## 14. PCA

PCA se usa únicamente para visualización. Las coordenadas 2D no sustituyen a la geometría del embedding original.

## 15. Diseño de un estudio real

Una comparación defendible debería, como mínimo:

- justificar la selección de obras;
- equilibrar tamaño y género cuando sea posible;
- documentar traducciones y ediciones;
- usar periodos con suficiente texto;
- incluir controles de frecuencia;
- examinar sensibilidad a ventana, vocabulario y dimensionalidad;
- aumentar bootstrap;
- contrastar el resultado con evidencia filológica/histórica;
- evitar interpretar correlación distribucional como causalidad.
