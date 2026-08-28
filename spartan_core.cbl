IDENTIFICATION DIVISION.
       PROGRAM-ID. SPARTAN-CORE.
       AUTHOR. ZORIOX ULTIMATE.
       *> ======================================================================
       *> SYSTEM       : SPARTAN Tactical Aerospace Node Database
       *> MODULE       : Command Center & Interactive ISAM Core
       *> ARCHITECTURE : TUI (Text User Interface) + Sequential Subprograms
       *> DESCRIPTION  : This monolithic module manages the interactive terminal.
       *>                It handles O(log n) B-Tree lookups, renders the UI via
       *>                the SCREEN SECTION, and delegates orbital mechanics math
       *>                to an internal sequential subprogram via CALL.
       *> ======================================================================

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           *> ------------------------------------------------------------------
           *> SEQUENTIAL INPUT STREAM (Raw Telemetry Payload)
           *> ------------------------------------------------------------------
           *> Binds a standard flat text file for linear, byte-by-byte ingestion.
           SELECT INIT-FILE ASSIGN TO "spartan_init.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

           *> ------------------------------------------------------------------
           *> INDEXED DATABASE ENGINE (ISAM B-Tree Structure)
           *> ------------------------------------------------------------------
           *> ACCESS MODE IS DYNAMIC: A hybrid setting permitting both bulk
           *> sequential writes (cold boot) and random queries (tactical loop).
           SELECT INDEXED-DB ASSIGN TO "spartan_tactical.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS DB-NODE-ID
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       *> ----------------------------------------------------------------------
       *> FLAT FILE DESCRIPTOR & BUFFER MAPPING
       *> ----------------------------------------------------------------------
       FD  INIT-FILE.
       01  INIT-REC.
           05  IN-NODE-TYPE        PIC X(10).
           05  IN-NODE-ID          PIC X(10).
           05  IN-INTEGRITY        PIC 9(03).
           05  IN-DELTA-V          PIC 9(05).

       *> ----------------------------------------------------------------------
       *> INDEXED DATABASE DESCRIPTOR & SCHEMA
       *> ----------------------------------------------------------------------
       *> Layout must exactly match the binary payload. DB-NODE-ID is the anchor.
       FD  INDEXED-DB.
       01  DB-RECORD.
           05  DB-NODE-TYPE        PIC X(10).
           05  DB-NODE-ID          PIC X(10).
           05  DB-INTEGRITY        PIC 9(03).
           05  DB-DELTA-V          PIC 9(05).

       WORKING-STORAGE SECTION.
       *> ----------------------------------------------------------------------
       *> SYSTEM STATE FLAGS & I/O ERROR HANDLING
       *> ----------------------------------------------------------------------
       01  WS-CONTROL-FLAGS.
           05  WS-EOF-INIT         PIC X(01) VALUE 'N'.
               88  END-OF-INIT     VALUE 'Y'.

       *> Catches 2-digit OS return codes during file operations.
       01  WS-FILE-STATUS          PIC X(02).
           88  FILE-NOT-FOUND      VALUE "35".
           88  FILE-SUCCESS        VALUE "00".

       *> ----------------------------------------------------------------------
       *> TACTICAL TUI VARIABLES (Bound to the SCREEN SECTION)
       *> ----------------------------------------------------------------------
       01  WS-UI-FIELDS.
           05  WS-USER-INPUT       PIC X(10) VALUE SPACES.
               88  EXIT-COMMAND    VALUE "QUIT      ".
           05  WS-ACTION-CODE      PIC X(01) VALUE SPACES.
           05  WS-ACTION-VALUE     PIC 9(03) VALUE ZEROES.
           05  WS-SYS-MESSAGE      PIC X(50) VALUE SPACES.
           05  WS-DUMMY-PAUSE      PIC X(01) VALUE SPACES.

       *> ----------------------------------------------------------------------
       *> TERMINAL GRAPHICS & UI LAYOUT
       *> ----------------------------------------------------------------------
       *> Defines the precise X/Y terminal coordinates and classic color palettes.
       SCREEN SECTION.
       01  CLEAR-SCREEN.
           05  BLANK SCREEN BACKGROUND-COLOR 0 FOREGROUND-COLOR 2.

       01  MAIN-HEADER-SCREEN.
           05  LINE 02 COL 10 VALUE "====================================================="
               FOREGROUND-COLOR 2.
           05  LINE 03 COL 10 VALUE "||           SPARTAN ORBITAL COMMAND CENTER        ||"
               FOREGROUND-COLOR 2 HIGHLIGHT.
           05  LINE 04 COL 10 VALUE "====================================================="
               FOREGROUND-COLOR 2.
           05  LINE 06 COL 10 VALUE "TARGET ASSET ID (or 'QUIT') : "
               FOREGROUND-COLOR 7.
           *> Input field linked directly to RAM (WS-USER-INPUT)
           05  INP-NODE-ID LINE 06 COL 40 PIC X(10) USING WS-USER-INPUT
               FOREGROUND-COLOR 2 HIGHLIGHT BACKGROUND-COLOR 0.

       01  ASSET-INFO-SCREEN.
           05  LINE 08 COL 10 VALUE ">> ASSET TELEMETRY ACQUIRED <<"
               FOREGROUND-COLOR 2 HIGHLIGHT.
           05  LINE 09 COL 10 VALUE "CLASSIFICATION : " FOREGROUND-COLOR 7.
           05  DISP-TYPE LINE 09 COL 27 PIC X(10) FROM DB-NODE-TYPE
               FOREGROUND-COLOR 3.
           05  LINE 10 COL 10 VALUE "HULL INTEGRITY : " FOREGROUND-COLOR 7.
           05  DISP-INT  LINE 10 COL 27 PIC 9(03) FROM DB-INTEGRITY
               FOREGROUND-COLOR 3.
           05  LINE 11 COL 10 VALUE "DELTA-V MARGIN : " FOREGROUND-COLOR 7.
           05  DISP-DELT LINE 11 COL 27 PIC 9(05) FROM DB-DELTA-V
               FOREGROUND-COLOR 3.

       01  ACTION-INPUT-SCREEN.
           05  LINE 13 COL 10 VALUE "TACTICAL DIRECTIVE (R=Refuel, D=Damage, N=None): "
               FOREGROUND-COLOR 7.
           05  INP-CMD LINE 13 COL 59 PIC X(01) USING WS-ACTION-CODE
               FOREGROUND-COLOR 2 HIGHLIGHT.
           05  LINE 14 COL 10 VALUE "PARAMETER MAGNITUDE (000-999)                  : "
               FOREGROUND-COLOR 7.
           05  INP-VAL LINE 14 COL 59 PIC 9(03) USING WS-ACTION-VALUE
               FOREGROUND-COLOR 2 HIGHLIGHT.

       01  MESSAGE-SCREEN.
           05  LINE 16 COL 10 PIC X(50) FROM WS-SYS-MESSAGE
               FOREGROUND-COLOR 6 HIGHLIGHT.
           05  LINE 17 COL 10 VALUE "PRESS ENTER TO CONTINUE..."
               FOREGROUND-COLOR 7.
           05  DUMMY-INP LINE 17 COL 37 PIC X TO WS-DUMMY-PAUSE.

       PROCEDURE DIVISION.
       0000-SYSTEM-BOOT.
           *> ------------------------------------------------------------------
           *> BOOT SEQUENCE AND DB VERIFICATION
           *> ------------------------------------------------------------------
           OPEN I-O INDEXED-DB
           IF FILE-NOT-FOUND
               *> Triggers sequential-to-binary compilation if .dat is missing
               PERFORM 1000-COMPILE-DATABASE
               OPEN I-O INDEXED-DB
           END-IF.

           *> Launch main interactive event loop
           PERFORM 2000-TERMINAL-LOOP UNTIL EXIT-COMMAND.

           *> Graceful shutdown sequence
           CLOSE INDEXED-DB.
           DISPLAY CLEAR-SCREEN.
           STOP RUN.

       1000-COMPILE-DATABASE.
           *> ------------------------------------------------------------------
           *> PHASE 1: SEQUENTIAL TO BINARY COMPILATION (COLD BOOT)
           *> ------------------------------------------------------------------
           DISPLAY "INITIALIZING B-TREE COMPILATION. PLEASE STAND BY..."
           OPEN INPUT INIT-FILE
           OPEN OUTPUT INDEXED-DB

           READ INIT-FILE AT END SET END-OF-INIT TO TRUE END-READ

           PERFORM UNTIL END-OF-INIT
               MOVE IN-NODE-TYPE TO DB-NODE-TYPE
               MOVE IN-NODE-ID   TO DB-NODE-ID
               MOVE IN-INTEGRITY TO DB-INTEGRITY
               MOVE IN-DELTA-V   TO DB-DELTA-V

               *> Writes to disk. COBOL engine natively handles B-Tree sorting
               WRITE DB-RECORD END-WRITE

               READ INIT-FILE AT END SET END-OF-INIT TO TRUE END-READ
           END-PERFORM

           CLOSE INIT-FILE
           CLOSE INDEXED-DB.

       2000-TERMINAL-LOOP.
           *> ------------------------------------------------------------------
           *> PHASE 2: TACTICAL TUI RENDER AND EVENT LISTENER
           *> ------------------------------------------------------------------
           *> Clear RAM buffers to prevent data ghosting between queries
           MOVE SPACES TO WS-USER-INPUT
           MOVE SPACES TO WS-ACTION-CODE
           MOVE ZEROES TO WS-ACTION-VALUE
           MOVE SPACES TO WS-SYS-MESSAGE

           DISPLAY CLEAR-SCREEN
           DISPLAY MAIN-HEADER-SCREEN

           *> Suspend thread execution and await operator input
           ACCEPT MAIN-HEADER-SCREEN

           *> ------------------------------------------------------------------
           *> INPUT SANITIZATION
           *> ------------------------------------------------------------------
           *> Converts input to uppercase in memory to guarantee case-insensitive
           *> B-Tree lookups, regardless of terminal visual rendering caches.
           INSPECT WS-USER-INPUT CONVERTING
               "abcdefghijklmnopqrstuvwxyz" TO
               "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

           IF NOT EXIT-COMMAND
               PERFORM 3000-TACTICAL-QUERY
           END-IF.

       3000-TACTICAL-QUERY.
           *> ------------------------------------------------------------------
           *> O(log n) RANDOM LOOKUP & COPROCESSOR DELEGATION
           *> ------------------------------------------------------------------
           MOVE WS-USER-INPUT TO DB-NODE-ID

           READ INDEXED-DB
               KEY IS DB-NODE-ID
               INVALID KEY
                   MOVE "[ERROR] ASSET IDENTIFIER NOT FOUND IN GRID."
                        TO WS-SYS-MESSAGE
                   DISPLAY MESSAGE-SCREEN
                   ACCEPT MESSAGE-SCREEN

               NOT INVALID KEY
                   *> Render asset telemetry and await tactical directive
                   DISPLAY ASSET-INFO-SCREEN
                   DISPLAY ACTION-INPUT-SCREEN
                   ACCEPT ACTION-INPUT-SCREEN

                   *> Sanitize action code (e.g., 'r' becomes 'R') in memory
                   INSPECT WS-ACTION-CODE CONVERTING
                       "abcdefghijklmnopqrstuvwxyz" TO
                       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

                   IF WS-ACTION-CODE = 'R' OR WS-ACTION-CODE = 'D'
                       *> ------------------------------------------------------
                       *> MODULAR CALL TO INTERNAL PHYSICS SUBPROGRAM
                       *> ------------------------------------------------------
                       *> BY REFERENCE: Passes memory pointer (two-way update).
                       *> BY CONTENT: Passes a read-only variable copy.
                       CALL "SPARTAN-PHYSICS" USING
                               BY REFERENCE DB-INTEGRITY
                               BY REFERENCE DB-DELTA-V
                               BY CONTENT   WS-ACTION-CODE
                               BY CONTENT   WS-ACTION-VALUE

                       *> Flush recalculated RAM buffers back to the physical disk
                       REWRITE DB-RECORD
                           INVALID KEY
                               MOVE "[FATAL] INDEX CORRUPTION DETECTED."
                                    TO WS-SYS-MESSAGE
                           NOT INVALID KEY
                               MOVE "[SUCCESS] TELEMETRY RECALIBRATED & SAVED."
                                    TO WS-SYS-MESSAGE
                       END-REWRITE
                   ELSE
                       MOVE "[INFO] NO TACTICAL DIRECTIVES ISSUED."
                            TO WS-SYS-MESSAGE
                   END-IF

                   *> Hold UI to display system outcome
                   DISPLAY MESSAGE-SCREEN
                   ACCEPT MESSAGE-SCREEN
           END-READ.
       END PROGRAM SPARTAN-CORE.

       *> ======================================================================
       *> INTERNAL PHYSICS COPROCESSOR (Sequential Subprogram)
       *> ======================================================================
       *> Appended internally to guarantee static linking and OS portability,
       *> while maintaining strict variable isolation via the LINKAGE SECTION.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SPARTAN-PHYSICS.
       AUTHOR. ZORIOX ULTIMATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       *> ----------------------------------------------------------------------
       *> HIGH-SPEED MATHEMATICAL BUFFERS
       *> ----------------------------------------------------------------------
       *> COMP (Computational) stores numbers natively in binary rather than text
       *> format, drastically speeding up CPU math. 'S' permits signed negatives.
       01  WS-CALC-INTEGRITY       PIC S9(04) COMP.
       01  WS-CALC-DELTA-V         PIC S9(06) COMP.
       01  WS-MULTIPLIER           PIC 9(03)  COMP.

       LINKAGE SECTION.
       *> ----------------------------------------------------------------------
       *> SHARED MEMORY MAP
       *> ----------------------------------------------------------------------
       *> Variable lengths must identically match the main program's CALL schema.
       01  LS-INTEGRITY            PIC 9(03).
       01  LS-DELTA-V              PIC 9(05).
       01  LS-ACTION-CODE          PIC X(01).
       01  LS-ACTION-VALUE         PIC 9(03).

       PROCEDURE DIVISION USING LS-INTEGRITY
                                LS-DELTA-V
                                LS-ACTION-CODE
                                LS-ACTION-VALUE.

       0000-PROCESS-PHYSICS.
           *> 1. Load incoming memory pointers into fast math buffers
           MOVE LS-INTEGRITY TO WS-CALC-INTEGRITY
           MOVE LS-DELTA-V   TO WS-CALC-DELTA-V

           *> 2. Execute operational mathematics based on tactical directive
           EVALUATE LS-ACTION-CODE
               WHEN 'R'
                   ADD LS-ACTION-VALUE TO WS-CALC-INTEGRITY
                   MULTIPLY LS-ACTION-VALUE BY 50 GIVING WS-MULTIPLIER
                   ADD WS-MULTIPLIER TO WS-CALC-DELTA-V

               WHEN 'D'
                   SUBTRACT LS-ACTION-VALUE FROM WS-CALC-INTEGRITY
                   MULTIPLY LS-ACTION-VALUE BY 25 GIVING WS-MULTIPLIER
                   SUBTRACT WS-MULTIPLIER FROM WS-CALC-DELTA-V

               WHEN OTHER
                   CONTINUE
           END-EVALUATE

           *> ------------------------------------------------------------------
           *> 3. HARDWARE SAFETY CLAMPING
           *> ------------------------------------------------------------------
           *> Enforces strict adherence to database schema limits
           IF WS-CALC-INTEGRITY > 100
               MOVE 100 TO WS-CALC-INTEGRITY
           END-IF
           IF WS-CALC-INTEGRITY < 0
               MOVE 0 TO WS-CALC-INTEGRITY
           END-IF

           IF WS-CALC-DELTA-V > 99999
               MOVE 99999 TO WS-CALC-DELTA-V
           END-IF
           IF WS-CALC-DELTA-V < 0
               MOVE 0 TO WS-CALC-DELTA-V
           END-IF

           *> 4. Overwrite shared memory pointers with sanitized data
           MOVE WS-CALC-INTEGRITY TO LS-INTEGRITY
           MOVE WS-CALC-DELTA-V   TO LS-DELTA-V

           *> 5. Safely return execution control to the main core routine
           EXIT PROGRAM.
       END PROGRAM SPARTAN-PHYSICS.
