import argparse
import random


def generate_spartan_init_load(filename: str, num_records: int, seed: int | None = None) -> None:
    """
    Generates a sequential flat file used by the SPARTAN COBOL system
    to build its initial Indexed Database (ISAM B-Tree).

    In legacy mainframe architectures, COBOL expects strict positional
    data rather than delimited formats (like CSV or JSON). This script
    creates a fixed-length string for each record, simulating a raw
    telemetry feed from an aerospace data link.

    The generated structure adheres to the following byte allocation:
    - Node Type (10 bytes): Tactical classification. Padded with spaces.
    - Node ID   (10 bytes): Primary Key for the COBOL Indexed file.
                            MUST be strictly unique. Padded with spaces.
    - Integrity (3 bytes) : Structural health (000-100). Zero-padded.
    - Delta-V   (5 bytes) : Orbital propellant margin. Zero-padded.
    - Total Record Length : 28 bytes + Newline character (\\n).

    Args:
        filename (str): The target file path for the sequential data.
        num_records (int): Total number of telemetry nodes to generate.
    """
    if not 1 <= num_records <= 9000:
        raise ValueError("num_records must be between 1 and 9000")

    rng = random.Random(seed)

    # Valid tactical classifications for the SPARTAN orbital grid
    node_types = ["HUB", "PROBE", "RELAY", "SATELLITE", "STATION"]

    # ----------------------------------------------------------------------
    # PRIMARY KEY CONSTRAINT ENFORCEMENT
    # ----------------------------------------------------------------------
    # We use a Python 'set' to guarantee O(1) lookup times when checking
    # for uniqueness. Indexed databases (ISAM) will throw a fatal Error 22
    # if we attempt to insert a duplicate RECORD KEY.
    generated_ids = set()

    try:
        # Open file with utf-8 encoding to prevent cross-platform byte issues.
        # COBOL will interpret these as standard single-byte ASCII characters.
        with open(filename, 'w', encoding='utf-8') as file:
            for _ in range(num_records):

                # ----------------------------------------------------------
                # 1. PRIMARY KEY GENERATION (10 Bytes)
                # ----------------------------------------------------------
                # Loop until a strictly unique 4-digit ID is generated.
                while True:
                    # Format as 'SPT-XXXX' and right-pad with spaces to
                    # strictly meet the 10-character limit required by PIC X(10).
                    node_id = f"SPT-{rng.randint(1000, 9999):04d}".ljust(10)
                    if node_id not in generated_ids:
                        generated_ids.add(node_id)
                        break

                # ----------------------------------------------------------
                # 2. CLASSIFICATION GENERATION (10 Bytes)
                # ----------------------------------------------------------
                # Randomly pick a string and right-pad it to 10 characters.
                # This maps directly to the DB-NODE-TYPE PIC X(10) field.
                node_type = rng.choice(node_types).ljust(10)

                # ----------------------------------------------------------
                # 3. TELEMETRY METRICS GENERATION
                # ----------------------------------------------------------
                # Hull Integrity (3 Bytes): Map to DB-INTEGRITY PIC 9(03)
                # Weighted heavily (70% chance) towards fully operational (100)
                # to simulate a stable aerospace fleet telemetry link.
                integrity = 100 if rng.random() > 0.3 else rng.randint(30, 99)

                # Delta-V Propellant (5 Bytes): Map to DB-DELTA-V PIC 9(05)
                delta_v = rng.randint(10000, 99999)

                # ----------------------------------------------------------
                # 4. POSITIONAL STRING ASSEMBLY & I/O COMMIT
                # ----------------------------------------------------------
                # Concatenate the fields enforcing strict width limits:
                # - {node_type} is already exactly 10 chars due to ljust().
                # - {node_id} is already exactly 10 chars due to ljust().
                # - {integrity:03d} forces exactly 3 digits, zero-padded.
                # - {delta_v:05d} forces exactly 5 digits, zero-padded.
                record = f"{node_type}{node_id}{integrity:03d}{delta_v:05d}\n"

                # Stream the 28-byte (+ newline) record to disk
                file.write(record)

        # System stdout to confirm execution
        print(f"[SPARTAN] Successfully compiled {num_records} unique assets.")
        print(f"[SPARTAN] Initialization payload written to: {filename}")

    except IOError as io_err:
        # Graceful error handling for permission or disk space issues
        print(f"[FATAL] Disk I/O failure during payload generation: {io_err}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate SPARTAN bootstrap telemetry")
    parser.add_argument("--output", default="spartan_init.txt")
    parser.add_argument("--records", type=int, default=200)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    if args.records < 1 or args.records > 9000:
        parser.error("--records must be between 1 and 9000")
    generate_spartan_init_load(args.output, args.records, seed=args.seed)
