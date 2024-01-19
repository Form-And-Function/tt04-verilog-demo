`define WORD_SIZE 16
`define ADDRESS_LEN 17
`define ADDRESS_IGNORED_BITS 7

module memory_controller (
  input  wire                        ena, // high when enabled
  input  wire                        clk, // clock
  input  wire                        rst_n, // reset negated (low to reset)
  input  wire [`ADDRESS_LEN - 1 : 0] mem_address, // address to read/write
  input  wire [`WORD_SIZE - 1 : 0]   mem_write_value, // value to write
  input  wire                        mem_write_enable, // high to write, low to read
  output reg [`WORD_SIZE - 1 : 0]    mem_read_value, // value read
  input  wire                        mem_request, // high to request read/write
  output reg                         mem_request_complete, // high when read/write complete
  output reg                         sd_cs, // chip select
  output reg                         sd_si, // serial in (master out, slave in)
  input  wire                        sd_so // serial out (master in, slave out)
  output reg                         sclk // serial clock
);

  parameter IDLE = 2'b00;
  parameter SEND = 2'b01;
  parameter RECEIVE = 2'b10;

  reg [1:0] state = IDLE;
  reg [3:0] bit_counter = 4'd0; // counter for how many bits we've sent

  always @(posedge clk) begin
    if (ena) begin
      if (!rst_n) begin
        state <= IDLE;
        bit_counter <= 4'd0;
        mem_read_value <= 8'd0;
        sd_cs <= 1;
        sclk <= 0;
        mem_request_complete <= 0;
      end else begin
        case (state)
          IDLE: begin
            if (mem_request) begin
              state <= SEND;
              bit_counter <= 4'd0;
              sd_cs <= 0;
              sclk <= 0;
            end
          end
          SEND: begin
            sclk <= ~sclk; // toggle clock
            if (bit_counter < 4'd8) begin // send 8 bits
              sd_si <= mem_address[16 - bit_counter]; // send address
              bit_counter <= bit_counter + 1; // increment counter
            end else begin // done sending
              state <= RECEIVE; // go to receive state
              bit_counter <= 4'd0;
            end
          end
          default: 
        endcase

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