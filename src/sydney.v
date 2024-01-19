`default_nettype none
`define WORD_SIZE 16
`define ADDRESS_SIZE 18 // 17 bits of address, 1 bit of read/write
`define ADDRESS_IGNORED_BITS 6
`define INSTRUCTION_SIZE 4
`define INSTRUCTION_DATA_SIZE 12

// define the instructions
`define INSTRUCTION_NOP 4'b0000
`define INSTRUCTION_ADD 4'b0001
`define INSTRUCTION_CMP 4'b0010
`define INSTRUCTION_MUL 4'b0011
`define INSTRUCTION_MOV 4'b0100
`define INSTRUCTION_MOD 4'b0101
`define INSTRUCTION_AND 4'b0110
`define INSTRUCTION_OR  4'b0111
`define INSTRUCTION_LD  4'b1000
`define INSTRUCTION_NOT 4'b1001
`define INSTRUCTION_SHL 4'b1010
`define INSTRUCTION_SHR 4'b1011
`define INSTRUCTION_JMP 4'b1100
`define INSTRUCTION_JZ  4'b1101
`define INSTRUCTION_JNZ 4'b1110
`define INSTRUCTION_HLT 4'b1111


//`define READ_ONLY_ABOVE 18'h20000

// main.v:
module Form_And_Function_cpu (
  input  wire [7:0] ui_in,   // dedicated inputs
  output wire [7:0] uo_out,  // dedicated outputs
  input  wire [7:0] uio_in,  // bidirectional input path
  output wire [7:0] uio_out, // bidirectional output path
  output wire [7:0] uio_oe,  // bidir output enable (high=out)
  input  wire       ena,     // high when enabled
  input  wire       clk,     // clock
  input  wire       rst_n    // reset negated (low to reset)
);
  wire sram_cs;
  wire sram_si;
  wire sram_so;
  assign sram_so = uio_in[0];
  assign uio_out[4] = sram_cs;
  assign uio_out[5] = sram_si;
  assign uio_oe[0] = 0;
  assign uio_oe[4] = 1;
  assign uio_oe[5] = 1;

  // Memory controller.
  reg [`ADDRESS_SIZE - 1 : 0] mem_address;
  reg [`WORD_SIZE - 1 : 0] mem_write_value;
  reg mem_write_enable;
  wire [`WORD_SIZE - 1 : 0] mem_read_value;
  reg mem_request;
  wire mem_request_complete;

  memory_controller memory_controller (
    .ena(ena),
    .clk(clk),
    .rst_n(rst_n),
    .mem_address(mem_address),
    .mem_write_value(mem_write_value),
    .mem_write_enable(mem_write_enable),
    .mem_read_value(mem_read_value),
    .mem_request(mem_request),
    .mem_request_complete(mem_request_complete),
    .sram_cs(sram_cs),
    .sram_si(sram_si),
    .sram_so(sram_so)
  );

  always @(posedge clk) begin
    if (ena) begin
      $display("mem_read_value: %b", mem_read_value);
      if (!rst_n) begin
        // Reset.
        mem_address <= 0;
        mem_write_value <= 0;
        mem_write_enable <= 0;
        mem_request <= 0;
      end else begin
        // Read from memory.
        if (mem_request_complete) begin
          $display("Read value: %b", mem_read_value);

          case (mem_read_value[`INSTRUCTION_SIZE + `INSTRUCTION_DATA_SIZE - 1 : `INSTRUCTION_DATA_SIZE])
            `INSTRUCTION_NOP: begin
              mem_address <= mem_address + 1;
              // Do nothing.
            end
            `INSTRUCTION_ADD: begin
              // Add.
              mem_write_value <= mem_read_value[11:8] + mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_CMP: begin
              // Compare.
              if (mem_read_value[11:8] == mem_read_value[7:4]) begin
                mem_write_value <= 0;
              end else if (mem_read_value[11:8] > mem_read_value[7:4]) begin
                mem_write_value <= 1;
              end else begin
                mem_write_value <= -1;
              end
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_MUL: begin
              // Multiply.
              mem_write_value <= mem_read_value[11:8] * mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_DIV: begin
              // Divide.
              mem_write_value <= mem_read_value[11:8] / mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_MOD: begin
              // Modulo.
              mem_write_value <= mem_read_value[11:8] % mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_AND: begin
              // And.
              mem_write_value <= mem_read_value[11:8] & mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_OR: begin
              // Or.
              mem_write_value <= mem_read_value[11:8] | mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_XOR: begin
              // Xor.
              mem_write_value <= mem_read_value[11:8] ^ mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_NOT: begin
              // Not.
              mem_write_value <= ~mem_read_value[11:8];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_SHL: begin
              // Shift left.
              mem_write_value <= mem_read_value[11:8] << mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_SHR: begin
              // Shift right.
              mem_write_value <= mem_read_value[11:8] >> mem_read_value[7:4];
              mem_write_enable <= 1;
              mem_address <= mem_address + 1;
            end
            `INSTRUCTION_JMP: begin
              // Jump.
              mem_address <= mem_read_value[11:0];
            end
            `INSTRUCTION_JZ: begin
              // Jump if zero.
              if (mem_read_value[11:8] == 0) begin
                mem_address <= mem_read_value[7:0];
              end else begin
                mem_address <= mem_address + 1;
              end
            end
            `INSTRUCTION_JNZ: begin
              // Jump if not zero.
              if (mem_read_value[11:8] != 0) begin
                mem_address <= mem_read_value[7:0];
              end else begin
                mem_address <= mem_address + 1;
              end
            end
            `INSTRUCTION_HLT: begin
              // Halt.
              mem_request <= 0;
            end 
            default: 
          endcase

          mem_request <= 0;
        end else begin
          mem_address <= 0;
          mem_write_value <= 0;
          mem_write_enable <= 0;
          mem_request <= 1;
        end
      end
    end
  end


endmodule

// instruction pointer: fetch the instruction at that adress, figure out what it says to do, and do it.
// 