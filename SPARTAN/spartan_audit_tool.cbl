IDENTIFICATION DIVISION.
       PROGRAM-ID. SPARTAN-AUDIT.
       AUTHOR. ZORIOX ULTIMATE.
       *> ======================================================================
       *> SYSTEM         : SPARTAN Tactical Aerospace Node Database
       *> MODULE         : ISAM Database Audit and Verification Utility
       *> ARCHITECTURE   : Monolithic Batch Extraction
       *> DESCRIPTION    : This utility performs a full sequential extraction
       *>                  of the binary indexed database (B-Tree). It formats
       *>                  the raw operational telemetry into a human-readable,
       *>                  strictly 60-byte column-aligned audit report.
       *> ======================================================================

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           *> ------------------------------------------------------------------
           *> ISAM DATABASE CONNECTION
           *> ------------------------------------------------------------------
           *> Although the physical file is an Indexed B-Tree, we set the
           *> ACCESS MODE to SEQUENTIAL. This forces the internal database
           *> engine to traverse the tree nodes in ascending order based
           *> on the RECORD KEY, creating an alphabetically sorted dump.
           SELECT INDEXED-DB ASSIGN TO "spartan_tactical.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS DB-NODE-ID.

           *> ------------------------------------------------------------------
           *> OUTPUT REPORT STREAM
           *> ------------------------------------------------------------------
           SELECT AUDIT-REPORT ASSIGN TO "spartan_audit_report.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       *> ----------------------------------------------------------------------
       *> BINARY DATABASE SCHEMA BINDING (28 Bytes total per record)
       *> ----------------------------------------------------------------------
       FD  INDEXED-DB.
       01  DB-RECORD.
           05  DB-NODE-TYPE        PIC X(10).
           05  DB-NODE-ID          PIC X(10).
           05  DB-INTEGRITY        PIC 9(03).
           05  DB-DELTA-V          PIC 9(05).

       *> ----------------------------------------------------------------------
       *> TEXT OUTPUT BUFFER (Strictly enforced 60 Bytes per line)
       *> ----------------------------------------------------------------------
       FD  AUDIT-REPORT.
       01  REPORT-LINE             PIC X(60).

       WORKING-STORAGE SECTION.
       *> ----------------------------------------------------------------------
       *> SYSTEM STATE FLAGS & ACCUMULATORS
       *> ----------------------------------------------------------------------
       01  WS-CONTROL-FLAGS.
           05  WS-EOF-DB           PIC X(01) VALUE 'N'.
               88  END-OF-DB       VALUE 'Y'.

       01  WS-RECORD-COUNT         PIC 9(04) VALUE 0.

       *> ----------------------------------------------------------------------
       *> ALIGNED DETAIL LINE BUFFER (Calculated exactly to 60 Bytes)
       *> ----------------------------------------------------------------------
       *> This structure acts as a template. By mapping data into the named
       *> variables (RPT-ID, RPT-TYPE, etc.), the FILLER spaces automatically
       *> maintain the structural integrity of the grid.
       01  WS-DETAIL-LINE.
           05  FILLER              PIC X(02) VALUE "| ".
           05  RPT-ID              PIC X(10).
           05  FILLER              PIC X(03) VALUE " | ".
           05  RPT-TYPE            PIC X(10).
           05  FILLER              PIC X(03) VALUE " | ".
           05  RPT-INTEGRITY       PIC 9(03).
           05  FILLER              PIC X(09) VALUE "%      | ".
           05  RPT-DELTA-V         PIC 9(05).
           05  FILLER              PIC X(15) VALUE "              |".

       PROCEDURE DIVISION.
       0000-START-AUDIT.
           *> ------------------------------------------------------------------
           *> MAIN EXECUTION THREAD
           *> ------------------------------------------------------------------
           DISPLAY "[INFO] Initializing SPARTAN Database Audit...".

           *> Allocate file locks
           OPEN INPUT INDEXED-DB
           OPEN OUTPUT AUDIT-REPORT

           PERFORM 1000-PRINT-HEADERS

           *> Prime the extraction loop by fetching the first alphabetical node
           READ INDEXED-DB NEXT RECORD
               AT END SET END-OF-DB TO TRUE
           END-READ

           *> Traverse the B-Tree structure
           PERFORM 2000-EXTRACT-RECORDS UNTIL END-OF-DB

           PERFORM 3000-PRINT-FOOTER

           *> Release file locks
           CLOSE INDEXED-DB
           CLOSE AUDIT-REPORT

           DISPLAY "[INFO] Audit complete. Check spartan_audit_report.txt".
           STOP RUN.

       1000-PRINT-HEADERS.
           *> ------------------------------------------------------------------
           *> INJECT TABLE METADATA AND HEADERS
           *> ------------------------------------------------------------------
           *> All lines injected here must match the 60-byte limit precisely.
           WRITE REPORT-LINE FROM
           "============================================================"
           WRITE REPORT-LINE FROM
           "| NODE ID    | CLASSIF.   | INTEGRITY | DELTA-V RESERVE    |"
           WRITE REPORT-LINE FROM
           "============================================================".

       2000-EXTRACT-RECORDS.
           *> ------------------------------------------------------------------
           *> RECORD PARSING AND FORMATTING
           *> ------------------------------------------------------------------
           ADD 1 TO WS-RECORD-COUNT

           *> Cast the binary payload into the text layout template
           MOVE DB-NODE-ID   TO RPT-ID
           MOVE DB-NODE-TYPE TO RPT-TYPE
           MOVE DB-INTEGRITY TO RPT-INTEGRITY
           MOVE DB-DELTA-V   TO RPT-DELTA-V

           *> Commit the constructed string to the file stream
           WRITE REPORT-LINE FROM WS-DETAIL-LINE

           *> Advance the database cursor to the next index key
           READ INDEXED-DB NEXT RECORD
               AT END SET END-OF-DB TO TRUE
           END-READ.

       3000-PRINT-FOOTER.
           *> ------------------------------------------------------------------
           *> REPORT TERMINATION AND STATISTICAL SUMMARY
           *> ------------------------------------------------------------------
           MOVE SPACES TO REPORT-LINE
           WRITE REPORT-LINE

           WRITE REPORT-LINE FROM
           "============================================================"

           *> Clean the memory buffer to prevent data ghosting
           MOVE SPACES TO REPORT-LINE

           *> Concatenate the final tally string dynamically
           STRING "TOTAL TACTICAL ASSETS VERIFIED: " WS-RECORD-COUNT
                  DELIMITED BY SIZE INTO REPORT-LINE

           WRITE REPORT-LINE
           WRITE REPORT-LINE FROM
           "============================================================".
