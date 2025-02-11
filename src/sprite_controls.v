module sprite_controls
(
    input btnX,
    input btnY,
    output reg [9:0] posX,
    output reg [9:0] posY
);
assign move_btnX = ~btnX;
assign move_btnY = ~btnY;

always @(posedge move_btnX) begin
    if (~&posX) begin 
        posX <= posX + 10;
    end else begin
        posX <= 0;
    end
end

always @(posedge move_btnY) begin
    if (~&posY) begin 
        posY <= posY + 10;
    end else begin
        posY <= 0;
    end
end

endmodule