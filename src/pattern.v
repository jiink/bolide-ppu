module pattern(
    input clock,
    input [9:0] spritePosX,
    input [9:0] spritePosY,
    input [12:0] x,
    input [12:0] y,
    output [7:0] r,
    output [7:0] g,
    output [7:0] b
);

localparam [7:0] SPRITE_WIDTH = 8; // = sprite height
// https://projectf.io/posts/hardware-sprites/
// sprite bitmap
reg [0:7] bitmap [8]; // Or should it be [7:0]?
initial begin
    bitmap[0]  = 8'b1111_1100;
    bitmap[1]  = 8'b1100_0000;
    bitmap[2]  = 8'b1100_0000;
    bitmap[3]  = 8'b1111_1000;
    bitmap[4]  = 8'b1100_0000;
    bitmap[5]  = 8'b1100_0000;
    bitmap[6]  = 8'b1100_0011;
    bitmap[7]  = 8'b0000_0011;
end
reg [9:0]liveSpritePosX; // register that spritePosX and Y are saved to
reg [9:0]liveSpritePosY;
// coordinates within sprite bitmap
reg[2:0] bmap_idx_x; // can go 0 to 8
reg[2:0] bmap_idx_y;
// status flags
reg spr_active; // Is the sprite on this line?
reg spr_begin; // Should the sprite be drawing *right now*?
reg spr_end; // A blip when the sprite line is done.
always_comb begin // What's the diff between always_comb and always @(*)?
    spr_active = (y - liveSpritePosY >= 0) && (y - liveSpritePosY < SPRITE_WIDTH); // width = height
    spr_begin = (x >= liveSpritePosX);
    spr_end = (bmap_idx_x == SPRITE_WIDTH - 1);
end
enum {
    IDLE,
    ACTIVE,
    WAIT_POS,
    SPR_LINE
} state;
reg pix; // 1 means light up pixel cuz of sprite, 0 means do nothing.
always_ff @(posedge clock) begin
    if (x == 0) begin // Line starts
        state <= ACTIVE; // see if this is our line
    end else begin
        case (state)
            ACTIVE: begin
                // If the sprite is on this line, great,
                // wait for the right column. If not,
                // sleep until maybe the next line 
                // has the sprite.
                state <= spr_active ? WAIT_POS : IDLE;
            end
            WAIT_POS: begin
                if (spr_begin) begin
                    // ok, right column now,
                    // now start putting sprite.
                    state <= SPR_LINE;
                    bmap_idx_x <= x - liveSpritePosX;
                    bmap_idx_y <= y - liveSpritePosY;
                end
            end
            SPR_LINE: begin
                // plotting a pixel until the sprite's time 
                // on the line is over.
                bmap_idx_x <= bmap_idx_x + 1;
                pix <= bitmap[bmap_idx_y][bmap_idx_x];
                if (spr_end) begin
                    state <= IDLE;
                    pix <= 0;
                end
            end
            default: state <= IDLE;
        endcase
    end
end


wire bottomLine;


wire [7:0] checkerBg;
assign checkerBg = x[7:0] ^ y[7:0];

assign r = checkerBg;
assign g = {8{pix}};
assign b = checkerBg;

assign bottomLine = (y == 767);
always @(posedge bottomLine) begin
    liveSpritePosX <= spritePosX;
    liveSpritePosY <= spritePosY;
end

endmodule