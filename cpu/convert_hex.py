# Convert Intel HEX format to simple hex format for RISC-V
with open('main.hex', 'r') as f:
    lines = f.readlines()

# Extract instructions starting from @00002340
instructions = []
data_section = []
current_section = None

for line in lines:
    line = line.strip()
    if line.startswith('@'):
        addr = int(line[1:], 16)
        if addr == 0x00002340:
            current_section = 'instructions'
        elif addr == 0x00000000:
            current_section = 'data'
    elif current_section == 'instructions':
        # Parse instruction bytes (little-endian)
        bytes_list = line.split()
        for i in range(0, len(bytes_list), 4):
            if i + 3 < len(bytes_list):
                # Convert little-endian bytes to instruction
                instr = bytes_list[i+3] + bytes_list[i+2] + bytes_list[i+1] + bytes_list[i]
                instructions.append(instr.lower())
    elif current_section == 'data':
        # Parse data bytes  
        bytes_list = line.split()
        for i in range(0, len(bytes_list), 4):
            if i + 3 < len(bytes_list):
                # Convert little-endian bytes to word
                word = bytes_list[i+3] + bytes_list[i+2] + bytes_list[i+1] + bytes_list[i]
                data_section.append(word.lower())

# Write cleaned instruction file
with open('fir_program_clean.hex', 'w') as f:
    for instr in instructions:
        f.write(instr + '\n')

# Write data file  
with open('fir_data_clean.hex', 'w') as f:
    for word in data_section:
        f.write(word + '\n')

print(f"Extracted {len(instructions)} instructions")
print(f"Extracted {len(data_section)} data words")
print(f"First instruction: {instructions[0] if instructions else 'None'}")
print(f"Last instruction: {instructions[-1] if instructions else 'None'}")
