#!/usr/bin/env python3
"""
RISC-V Instruction Decoder
Decodes 32-bit RISC-V instructions and shows all fields
"""

def decode_instruction(instr_hex):
    """Decode a RISC-V instruction from hex string"""
    if isinstance(instr_hex, str):
        if instr_hex.startswith('0x'):
            instr = int(instr_hex, 16)
        else:
            instr = int(instr_hex, 16)
    else:
        instr = instr_hex
    
    print(f"Instruction: 0x{instr:08x}")
    print(f"Binary:      {instr:032b}")
    print()
    
    # Extract basic fields
    opcode = instr & 0x7F           # bits [6:0]
    rd = (instr >> 7) & 0x1F        # bits [11:7]
    funct3 = (instr >> 12) & 0x7    # bits [14:12]
    rs1 = (instr >> 15) & 0x1F      # bits [19:15]
    rs2 = (instr >> 20) & 0x1F      # bits [24:20]
    funct7 = (instr >> 25) & 0x7F   # bits [31:25]
    
    # For immediate instructions
    imm_i = (instr >> 20) & 0xFFF   # I-type immediate [31:20]
    if imm_i & 0x800:  # Sign extend
        imm_i |= 0xFFFFF000
    
    imm_s = ((instr >> 25) << 5) | ((instr >> 7) & 0x1F)  # S-type immediate
    if imm_s & 0x800:  # Sign extend
        imm_s |= 0xFFFFF000
    
    imm_u = instr & 0xFFFFF000      # U-type immediate [31:12]
    
    print("Field breakdown:")
    print(f"opcode:  {opcode:07b} (0x{opcode:02x}) - bits [6:0]")
    print(f"rd:      {rd:05b} (x{rd}) - bits [11:7]")
    print(f"funct3:  {funct3:03b} (0x{funct3:x}) - bits [14:12]")
    print(f"rs1:     {rs1:05b} (x{rs1}) - bits [19:15]")
    print(f"rs2:     {rs2:05b} (x{rs2}) - bits [24:20]")
    print(f"funct7:  {funct7:07b} (0x{funct7:02x}) - bits [31:25]")
    print()
    
    # Decode instruction type and operation
    inst_name = decode_operation(opcode, funct3, funct7, rd, rs1, rs2, imm_i, imm_s, imm_u, instr)
    return inst_name

def decode_operation(opcode, funct3, funct7, rd, rs1, rs2, imm_i, imm_s, imm_u, instr=0):
    """Decode the specific operation based on opcode and function fields"""
    
    if opcode == 0x33:  # R-type
        print("Type: R-type")
        if funct7 == 0x01:  # M-extension
            print("Extension: M (Multiplication/Division)")
            m_ops = {
                0x0: "MUL", 0x1: "MULH", 0x2: "MULHSU", 0x3: "MULHU",
                0x4: "DIV", 0x5: "DIVU", 0x6: "REM", 0x7: "REMU"
            }
            if funct3 in m_ops:
                op = m_ops[funct3]
                print(f"Operation: {op} x{rd}, x{rs1}, x{rs2}")
                return f"{op} x{rd}, x{rs1}, x{rs2}"
        else:  # Standard R-type
            print("Extension: Base")
            if funct3 == 0x0:
                op = "ADD" if funct7 == 0x00 else "SUB"
            elif funct3 == 0x1: op = "SLL"
            elif funct3 == 0x2: op = "SLT"
            elif funct3 == 0x3: op = "SLTU"
            elif funct3 == 0x4: op = "XOR"
            elif funct3 == 0x5: op = "SRL" if funct7 == 0x00 else "SRA"
            elif funct3 == 0x6: op = "OR"
            elif funct3 == 0x7: op = "AND"
            else: op = "UNKNOWN"
            print(f"Operation: {op} x{rd}, x{rs1}, x{rs2}")
            return f"{op} x{rd}, x{rs1}, x{rs2}"
    
    elif opcode == 0x13:  # I-type ALU
        print("Type: I-type (ALU)")
        ops = {0x0: "ADDI", 0x2: "SLTI", 0x3: "SLTIU", 0x4: "XORI", 
               0x6: "ORI", 0x7: "ANDI", 0x1: "SLLI", 0x5: "SRLI/SRAI"}
        op = ops.get(funct3, "UNKNOWN")
        print(f"Operation: {op} x{rd}, x{rs1}, {imm_i}")
        return f"{op} x{rd}, x{rs1}, {imm_i}"
    
    elif opcode == 0x03:  # Load
        print("Type: I-type (Load)")
        load_ops = {0x0: "LB", 0x1: "LH", 0x2: "LW", 0x4: "LBU", 0x5: "LHU"}
        op = load_ops.get(funct3, "UNKNOWN")
        print(f"Operation: {op} x{rd}, {imm_i}(x{rs1})")
        return f"{op} x{rd}, {imm_i}(x{rs1})"
    
    elif opcode == 0x23:  # Store
        print("Type: S-type (Store)")
        store_ops = {0x0: "SB", 0x1: "SH", 0x2: "SW"}
        op = store_ops.get(funct3, "UNKNOWN")
        print(f"Operation: {op} x{rs2}, {imm_s}(x{rs1})")
        return f"{op} x{rs2}, {imm_s}(x{rs1})"
    
    elif opcode == 0x63:  # Branch
        print("Type: B-type (Branch)")
        branch_ops = {0x0: "BEQ", 0x1: "BNE", 0x4: "BLT", 0x5: "BGE", 0x6: "BLTU", 0x7: "BGEU"}
        op = branch_ops.get(funct3, "UNKNOWN")
        # Calculate branch immediate
        imm_b = ((instr >> 31) << 12) | (((instr >> 7) & 0x1) << 11) | \
                (((instr >> 25) & 0x3F) << 5) | (((instr >> 8) & 0xF) << 1)
        if imm_b & 0x1000:  # Sign extend
            imm_b |= 0xFFFFE000
        print(f"Operation: {op} x{rs1}, x{rs2}, {imm_b}")
        return f"{op} x{rs1}, x{rs2}, {imm_b}"
    
    elif opcode == 0x37:  # LUI
        print("Type: U-type (LUI)")
        print(f"Operation: LUI x{rd}, 0x{imm_u >> 12:05x}")
        return f"LUI x{rd}, 0x{imm_u >> 12:05x}"
    
    elif opcode == 0x17:  # AUIPC
        print("Type: U-type (AUIPC)")
        print(f"Operation: AUIPC x{rd}, 0x{imm_u >> 12:05x}")
        return f"AUIPC x{rd}, 0x{imm_u >> 12:05x}"
    
    elif opcode == 0x6F:  # JAL
        print("Type: J-type (JAL)")
        # Calculate jump immediate
        imm_j = ((instr >> 31) << 20) | (((instr >> 12) & 0xFF) << 12) | \
                (((instr >> 20) & 0x1) << 11) | (((instr >> 21) & 0x3FF) << 1)
        if imm_j & 0x100000:  # Sign extend
            imm_j |= 0xFFE00000
        print(f"Operation: JAL x{rd}, {imm_j}")
        return f"JAL x{rd}, {imm_j}"
    
    elif opcode == 0x67:  # JALR
        print("Type: I-type (JALR)")
        print(f"Operation: JALR x{rd}, x{rs1}, {imm_i}")
        return f"JALR x{rd}, x{rs1}, {imm_i}"
    
    else:
        print(f"Type: Unknown (opcode=0x{opcode:02x})")
        return "UNKNOWN"

def main():
    """Interactive decoder"""
    print("RISC-V Instruction Decoder")
    print("=" * 40)
    
    while True:
        try:
            instr_input = input("\nEnter instruction (hex, or 'quit'): ").strip()
            if instr_input.lower() in ['quit', 'q', 'exit']:
                break
            
            if not instr_input:
                continue
                
            decode_instruction(instr_input)
            print("-" * 40)
            
        except ValueError:
            print("Invalid hex input! Please enter a valid hex number.")
        except KeyboardInterrupt:
            print("\nGoodbye!")
            break

if __name__ == "__main__":
    import sys
    import os
    
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        # Check if it's a file
        if os.path.isfile(arg):
            with open(arg, 'r') as f:
                for i, line in enumerate(f):
                    line = line.strip()
                    if line and not line.startswith('#'):
                        print(f"Line {i+1}: 0x{line} - ", end="")
                        decode_instruction(line)
        else:
            # Single instruction
            decode_instruction(arg)
    else:
        # Interactive mode
        main()