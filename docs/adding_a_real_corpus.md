# Añadir un corpus real

## 1. Derechos y procedencia

No copies una obra al repositorio sin comprobar que su licencia permite redistribuirla. Si el texto no puede publicarse, mantenlo localmente: `data/raw/` está preparado para ignorar corpus añadidos por el usuario.

La configuración y los metadatos sí deben conservarse, siempre que no revelen información restringida.

## 2. Preparar el archivo

La versión base ingiere texto plano UTF-8 (`.txt`). Si la fuente está en PDF, EPUB, HTML u OCR, realiza la extracción previamente y documenta el procedimiento. No mezcles silenciosamente texto corregido a mano con OCR bruto.

## 3. SHA-256

En Linux:

```bash
sha256sum data/raw/mi_corpus/obra.txt
```

Copia el hash a `config/corpora.toml`.

## 4. Entrada de metadatos

Ejemplo:

```toml
[[documents]]
id = "work_edition_01"
group = "period_a"
label = "Periodo A"
period = "1750-1800"
work = "Título de la obra"
author = "Autor"
year = 1770
original_year = 1768
language = "es"
original_language = "fr"
translator = "Nombre del traductor"
edition = "Editorial, edición, año"
genre = "philosophical prose"
source = "Descripción o referencia de procedencia"
license = "Estado de derechos / licencia"
path = "data/raw/period_a/work.txt"
sha256 = "..."
```

## 5. Traducciones

Si `language` y `original_language` son distintos, la configuración base exige `translator`.

No mezcles sin justificación traducciones de autores diferentes con originales de otros autores: el traductor puede alterar vocabulario, registro y relaciones semánticas.

Cuando sea viable, diseña uno de estos estudios:

- todo en lengua original y dentro de la misma lengua;
- todas las obras en una misma lengua de traducción con ediciones controladas;
- análisis separado por idioma;
- backend cross-lingual validado específicamente, que no forma parte de v0.2.0.

## 6. Conceptos

Edita `config/concepts.toml`. Evita listas de sinónimos excesivamente amplias: un alias nuevo cambia operacionalmente la definición del concepto.

Toda modificación de la ontología conceptual debería quedar asociada a un commit/tag del análisis.

## 7. Stop-words y valencia

`stopwords_en.txt` y `valence_en.toml` son recursos demostrativos. Para otro idioma o periodo crea recursos nuevos y cambia las rutas en `pipeline.toml`.

La lista de stop-words solo afecta DTM/TF-IDF por defecto.

## 8. Validación

```bash
julia --project=. scripts/validate_corpus.jl
```

La validación comprueba:

- IDs únicos;
- existencia de archivos;
- metadatos mínimos;
- traductor si procede;
- formato y coincidencia SHA-256.

## 9. Análisis de sensibilidad

Antes de publicar resultados, repite el estudio variando de forma razonable:

- `window`;
- `minimum_count`;
- `maximum_vocabulary`;
- `dimension`;
- tamaño de bloque;
- número de réplicas;
- aliases conceptuales.

Una conclusión que desaparece con cambios pequeños de hiperparámetros debe tratarse como inestable.
