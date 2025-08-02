def check_instruction_file(file_path):
    MAX_LOCATIONS = 256
    INSTRUCTION_WIDTH_BITS = 32
    INSTRUCTION_WIDTH_HEX = INSTRUCTION_WIDTH_BITS // 4  

    with open(file_path, 'r') as f:
        lines = [line.strip() for line in f if line.strip() != ""]

    if len(lines) > MAX_LOCATIONS:
        print(f"Error: Too many instructions ({len(lines)}). Max allowed is {MAX_LOCATIONS}.")
        return


    for i, inst in enumerate(lines):
        if len(inst) != INSTRUCTION_WIDTH_HEX:
            print(f"Error: Instruction on line {i+1} is not 32 bits (found {len(inst)*4} bits).")
            return

    print("✅ Valid instruction file.")
    last_instruction = lines[-1]
    print(f"Last instruction: 32'h{last_instruction.upper()}")


check_instruction_file('program.hex')