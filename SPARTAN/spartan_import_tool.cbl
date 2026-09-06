       IDENTIFICATION DIVISION.
       PROGRAM-ID. SPARTAN-IMPORT-TOOL.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IMPORT-FILE ASSIGN TO "spartan_import.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IMPORT-STATUS.
           SELECT INDEXED-DB ASSIGN TO "spartan_tactical.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS DB-NODE-ID
               FILE STATUS IS WS-DB-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD IMPORT-FILE.
       01 IMPORT-REC.
          05 IN-NODE-TYPE PIC X(10).
          05 IN-NODE-ID PIC X(10).
          05 IN-INTEGRITY PIC 9(03).
          05 IN-DELTA-V PIC 9(05).
       FD INDEXED-DB.
       01 DB-REC.
          05 DB-NODE-TYPE PIC X(10).
          05 DB-NODE-ID PIC X(10).
          05 DB-INTEGRITY PIC 9(03).
          05 DB-DELTA-V PIC 9(05).
       WORKING-STORAGE SECTION.
       01 WS-IMPORT-STATUS PIC X(02).
       01 WS-DB-STATUS PIC X(02).
       01 WS-EOF PIC X VALUE 'N'.
          88 END-OF-IMPORT VALUE 'Y'.
       01 WS-COUNT PIC 9(06) VALUE ZERO.
       PROCEDURE DIVISION.
       MAIN.
           OPEN INPUT IMPORT-FILE
           IF WS-IMPORT-STATUS NOT = "00"
               DISPLAY "[SPARTAN] No import queue available."
               STOP RUN
           END-IF
           OPEN I-O INDEXED-DB
           IF WS-DB-STATUS NOT = "00"
               DISPLAY "[SPARTAN] Indexed DB missing. Run spartan_core first."
               CLOSE IMPORT-FILE
               STOP RUN
           END-IF
           READ IMPORT-FILE AT END SET END-OF-IMPORT TO TRUE END-READ
           PERFORM UNTIL END-OF-IMPORT
               MOVE IN-NODE-ID TO DB-NODE-ID
               READ INDEXED-DB KEY IS DB-NODE-ID
                   INVALID KEY
                       MOVE IN-NODE-TYPE TO DB-NODE-TYPE
                       MOVE IN-NODE-ID TO DB-NODE-ID
                       MOVE IN-INTEGRITY TO DB-INTEGRITY
                       MOVE IN-DELTA-V TO DB-DELTA-V
                       WRITE DB-REC
                   NOT INVALID KEY
                       MOVE IN-NODE-TYPE TO DB-NODE-TYPE
                       MOVE IN-INTEGRITY TO DB-INTEGRITY
                       MOVE IN-DELTA-V TO DB-DELTA-V
                       REWRITE DB-REC
               END-READ
               ADD 1 TO WS-COUNT
               READ IMPORT-FILE AT END SET END-OF-IMPORT TO TRUE END-READ
           END-PERFORM
           CLOSE INDEXED-DB IMPORT-FILE
           OPEN OUTPUT IMPORT-FILE
           CLOSE IMPORT-FILE
           DISPLAY "[SPARTAN] Imported/updated records: " WS-COUNT
           STOP RUN.
