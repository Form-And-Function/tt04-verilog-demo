`define WORD_SIZE 16
`define ADDRESS_LEN 17
`define ADDRESS_IGNORED_BITS 7

module memory_controller (
  input  wire                        ena,
  input  wire                        clk,
  input  wire                        rst_n,
  input  wire [`ADDRESS_LEN - 1 : 0] mem_address,
  input  wire [`WORD_SIZE - 1 : 0]   mem_write_value,
  input  wire                        mem_write_enable,
  output reg [`WORD_SIZE - 1 : 0]    mem_read_value,
  input  wire                        mem_request,
  output reg                         mem_request_complete,
  output reg                         sram_cs,
  output reg                         sram_si,
  input  wire                        sram_so
);

  reg [6:0] counter;

  always @(posedge clk) begin
    if (ena) begin
      if (!rst_n) begin
        counter <= 0;
        sram_cs <= 1;
        mem_request_complete <= 0;
      end else begin
        if (mem_request) begin
          sram_cs <= 0;
          // The first seven bits are always 0, 0, 0, 0, 0, 0, 1
          if (counter < 6) begin
            sram_si <= 0;
          end else if (counter == 6) begin
            sram_si <= 1;
          end else if (counter == 7) begin
            // Then the eighth bit is 0 if we're writing, 1 if we're reading.
            sram_si <= !mem_write_enable;
          end else if (counter < 8 + `ADDRESS_IGNORED_BITS) begin
            sram_si <= 0;
          end else if (counter < 32) begin
            // Then the next 17 bits are the address.
            sram_si <= mem_address[`ADDRESS_LEN - (counter - 8 - `ADDRESS_IGNORED_BITS) - 1];
          end else if (counter < 32 + `WORD_SIZE) begin
            if (mem_write_enable) begin
              // Finally we send the bits to write, if relevant.
              sram_si <= mem_write_value[counter - 32];
            end else begin
              // Otherwise we read the bits.
              $display("Reading bit %d = %d  have: %b", counter - 32, sram_so, mem_read_value);
              mem_read_value[counter - 32] <= sram_so;
            end
          end

          if (counter < 32 + `WORD_SIZE) begin
            counter <= counter + 1;
          end else begin
            counter <= 32 + `WORD_SIZE;
            mem_request_complete <= 1;
            sram_cs <= 1;
          end
        end else begin
          counter <= 0;
          mem_request_complete <= 0;
        end
      end
    end else begin
      sram_cs <= 1;
    end
  end
endmodule