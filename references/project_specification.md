---
tags:
  - filosofía
  - religión
  - software
project_name: ETHOS.jl
project_acronym: Evolution of Textual Humanism, Ontology and Semantics
status: Architecture & Planning
---
# 📜 Proyecto: ETHOS.jl
## Evolution of Textual Humanism, Ontology and Semantics
## Análisis de Lenguaje Natural en Textos Sagrados, Filosóficos y Éticos

### 1. 🎯 Visión General
**ETHOS.jl** es un proyecto de Ciencia de Datos y Procesamiento de Lenguaje Natural (NLP) desarrollado en Julia. Su objetivo principal es rastrear la evolución computacional de la moralidad y los conceptos humanistas a lo largo de la historia de la literatura.

El sistema ingerirá y procesará corpus de textos sagrados, tratados filosóficos de la Ilustración y obras maestras de la ciencia ficción dura para comparar la frecuencia, el sentimiento y la evolución del contexto de conceptos abstractos como "compasión", "deber", "existencia" o "alma". Se utilizarán modelos vectoriales (Word Embeddings) para mapear topológicamente las relaciones semánticas entre estas ideas en diferentes paradigmas culturales.

---

### 2. 🛠️ Stack Tecnológico y Entorno
* **Lenguaje:** Julia (v1.10+ recomendado) gestionado a través de `juliaup`.
* **Entorno:** Visual Studio Code (VSC) sobre **Linux**.
* **Librerías Clave de Julia:**
    * `TextAnalysis.jl`: Para la limpieza de texto, tokenización y creación de Document-Term Matrices.
    * `Word2Vec.jl` o `Embeddings.jl`: Para la vectorización semántica de los conceptos.
    * `Languages.jl`: Para el manejo de stop-words y derivación morfológica (stemming) en varios idiomas.
    * `DataFrames.jl`: Para la estructuración y manipulación de las métricas obtenidas.
    * `Makie.jl` / `Plots.jl`: Para la visualización de clusters semánticos (ej. PCA o t-SNE de las palabras).

---

### 3. 📂 Estructura de Directorios (Standard Julia Project)
El proyecto seguirá una arquitectura modular limpia para separar los datos crudos de los scripts de análisis:

ETHOS/
├── Project.toml              # Dependencias y metadatos del entorno de Julia
├── Manifest.toml             # Versiones bloqueadas de las dependencias
├── README.md                 # Documentación general del proyecto
├── data/                     # Almacenamiento local de corpus (ignorado en git)
│   ├── raw/                  # Textos originales en .txt o .pdf sin procesar
│   └── processed/            # Textos limpios, tokenizados o vectorizados (.csv, .jld2)
├── notebooks/                # Jupyter o Pluto notebooks para exploración inicial
│   └── 01_data_exploration.jl
├── src/                      # Código fuente del módulo (Lógica central)
│   ├── ETHOS.jl      # Archivo principal del módulo
│   ├── cleaning.jl           # Funciones de normalización y tokenización
│   ├── vectorization.jl      # Funciones para crear embeddings
│   └── visualization.jl      # Código para exportar gráficas de clusters
└── scripts/                  # Scripts ejecutables (entry points)
    └── run_pipeline.jl       # Script que orquesta todo el proceso

---

### 4. 📐 Reglas y Normas Estrictas de Desarrollo
La interacción con la IA y el desarrollo del código están regidos por las siguientes normativas:

#### A. Arquitectura de Código
1. **Language Policy (Code):** Absolutamente todo el código, incluyendo nombres de variables, lógica, funciones, comentarios en línea y docstrings, debe escribirse exclusivamente en **inglés**.
2. **Style Guide:** El código debe adherirse a los estándares oficiales de formato y convenciones de la comunidad de Julia.
3. **Modularity:** Las funciones deben ser puras en la medida de lo posible, separando estrictamente la ingesta de datos, la limpieza y el análisis matemático.

#### B. Interfaz y Comunicación
1. **Language Policy (Chat):** Toda la comunicación conversacional, explicaciones teóricas, análisis filosóficos y debates técnicos dirigidos al usuario deben estar estrictamente en **español**.
2. **Anti-Spoiler Protocol:** Se mantiene una política estricta y absoluta de **cero spoilers**. Al debatir sobre ciencia ficción, literatura fantástica o cualquier otro medio narrativo analizado, está prohibido revelar giros de trama, finales o muertes de personajes a menos que el usuario lo solicite de forma explícita.

---

### 5. 🚀 Hoja de Ruta (Roadmap)
- [ ] Inicializar el entorno en Linux y generar la estructura de directorios.
- [ ] Desarrollar el pipeline de limpieza (`cleaning.jl`): eliminación de ruido, normalización a minúsculas, remoción de stop-words.
- [ ] Crear el primer Corpus de prueba (ej. un tratado corto) y generar su Matriz de Términos del Documento (DTM).
- [ ] Entrenar o aplicar un modelo Word2Vec para observar la proximidad espacial entre las palabras clave seleccionadas.

---

### 📝 Prompt Inicial para la IA
*(Copiar y pegar este texto en una nueva conversación habiendo adjuntado este archivo .md)*

> Actúa como mi socio experto en desarrollo de software con Julia, especializado en Procesamiento de Lenguaje Natural (NLP) y con profundos conocimientos en humanidades y filosofía.
>
> Te adjunto el documento maestro de nuestro proyecto, **ETHOS.jl**. Familiarízate con la visión general, la estructura de directorios y, muy especialmente, con las reglas estrictas de desarrollo y comunicación (idioma y cero spoilers).
>
> Para nuestro primer paso, necesito que me ayudes a configurar el esqueleto del proyecto.
> 1. Proporciona los comandos de terminal de Linux/Julia necesarios para inicializar el entorno y crear la estructura de carpetas descrita.
> 2. Escribe el contenido inicial del archivo `src/cleaning.jl`. Debe contener una función robusta que reciba una cadena de texto cruda (raw text string) y devuelva una lista de tokens limpios (sin puntuación, en minúsculas y sin espacios extra).
> 3. Asegúrate de cumplir con todas las reglas de idioma indicadas en el archivo .md.
