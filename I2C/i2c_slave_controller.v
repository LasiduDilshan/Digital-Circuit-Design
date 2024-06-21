`timescale 1ns / 1ps

module i2c_slave_controller(
    input wire clk,
    input wire rst,
    input wire [6:0] addr,
    output reg [7:0] data_out,
    input wire [7:0] data_in,
    inout wire i2c_sda,
    inout wire i2c_scl,
    output reg ack
);

    localparam IDLE = 0;
    localparam RECEIVE_ADDRESS = 1;
    localparam SEND_ACK = 2;
    localparam RECEIVE_DATA = 3;
    localparam SEND_DATA = 4;
    localparam STOP = 5;
    
    reg [2:0] state = IDLE;
    reg [7:0] saved_data;
    reg [6:0] received_addr;
    reg [7:0] received_data;
    reg [7:0] counter;
    reg sda_out;
    reg write_enable;

    assign i2c_sda = (write_enable) ? sda_out : 1'bz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            saved_data <= 8'd0;
            received_addr <= 7'd0;
            received_data <= 8'd0;
            counter <= 8'd0;
            sda_out <= 1'b1;
            write_enable <= 1'b0;
            ack <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_condition_detected) begin
                        state <= RECEIVE_ADDRESS;
                        counter <= 7;
                    end
                end
                RECEIVE_ADDRESS: begin
                    if (counter == 0) begin
                        received_addr <= {received_addr[5:0], i2c_sda};
                        if (received_addr == addr) begin
                            state <= SEND_ACK;
                        end else begin
                            state <= STOP;
                        end
                    end else begin
                        received_addr[counter] <= i2c_sda;
                        counter <= counter - 1;
                    end
                end
                SEND_ACK: begin
                    write_enable <= 1'b1;
                    sda_out <= 1'b0;
                    ack <= 1'b1;
                    if (rw_bit == 1) begin // Write operation
                        state <= RECEIVE_DATA;
                    end else begin // Read operation
                        state <= SEND_DATA;
                    end
                end
                RECEIVE_DATA: begin
                    write_enable <= 1'b0;
                    if (counter == 0) begin
                        received_data[counter] <= i2c_sda;
                        saved_data <= received_data;
                        state <= SEND_ACK;
                    end else begin
                        received_data[counter] <= i2c_sda;
                        counter <= counter - 1;
                    end
                end
                SEND_DATA: begin
                    write_enable <= 1'b1;
                    sda_out <= data_out[counter];
                    if (counter == 0) begin
                        state <= STOP;
                    end else begin
                        counter <= counter - 1;
                    end
                end
                STOP: begin
                    state <= IDLE;
                    write_enable <= 1'b0;
                    sda_out <= 1'b1;
                    ack <= 1'b0;
                end
            endcase
        end
    end

    // Assuming start_condition_detected and rw_bit signals are generated elsewhere in the design
    wire start_condition_detected;
    wire rw_bit;

    // Dummy implementation for start_condition_detected and rw_bit
    // Replace with your actual start condition and RW bit detection logic
    assign start_condition_detected = (i2c_sda == 0 && i2c_scl == 1); // Example logic
    assign rw_bit = received_addr[0]; // Example logic

endmodule
