module hdmiController(
    input pixelClk,     //25MHz for 640x480@60fps
    input tmdsClk,      //250MHz for 640x480@60fps
    input reset,        //active low
    input [7:0] vgaRed, 
    input [7:0] vgaGreen, 
    input [7:0] vgaBlue,
    output [2:0]tmdsPos,
    output [2:0]tmdsNeg,
    output tmdsPosClk,
    output tmdsNegClk,
    );

    // horizontal timings
    parameter HA_END = 639;           // end of active pixels
    parameter HS_STA = HA_END + 16;   // sync starts after front porch
    parameter HS_END = HS_STA + 96;   // sync ends
    parameter LINE   = 799;         // last pixel on line (after back porch)

    // vertical timings
    parameter VA_END = 479;           // end of active pixels
    parameter VS_STA = VA_END + 10;   // sync starts after front porch
    parameter VS_END = VS_STA + 2;    // sync ends
    parameter SCREEN = 524;        // last line on screen (after back porch)

////////////////////////////////////////////////////////
    reg [9:0] screenPosX, screenPosY;
    reg hSync, vSync, drawArea;

    // Control screenPos now
    always @(posedge pixelClk)
    if (~reset)
        screenPosX <= 0;
    else
        screenPosX <= (screenPosX==LINE) ? 0 : screenPosX+1;
    always @(posedge pixelClk)
    if (~reset)
        screenPosY <= 0;
    else if (screenPosX==LINE) begin
        screenPosY <= (screenPosY==SCREEN) ? 0 : screenPosY+1;
    end

    // Signal end of line, end of frame
 // always @(posedge pixelClk) begin
 //   o_newline  <= (screenPosX==639) ? 1 : 0;
 //   o_newframe <= (screenPosX==639) && (screenPosY==479) ? 1 : 0;
 // end

    // Determine when we are in a drawable area
    always @(posedge pixelClk)
    drawArea <= (screenPosX<640) && (screenPosY<480);

    // Generate horizontal and vertical sync pulses
    always @(posedge pixelClk)
    hSync <= ~((screenPosX>=656) && (screenPosX<752));
    always @(posedge pixelClk)
    vSync <= ~((screenPosY>=490) && (screenPosY<492));

    // Convert the 8-bit colours into 10-bit TMDS values
    wire [9:0] tmdsRed, tmdsGreen, tmdsBlue;
    tmdsEncoder encodeR(.clk(pixelClk), .VD(vgaRed), .CD(2'b00),
                                          .VDE(drawArea), .TMDS(tmdsRed));
    tmdsEncoder encodeG(.clk(pixelClk), .VD(vgaGreen), .CD(2'b00),
                                          .VDE(drawArea), .TMDS(tmdsGreen));
    tmdsEncoder encodeB(.clk(pixelClk), .VD(vgaBlue), .CD({vSync,hSync}),
                                          .VDE(drawArea), .TMDS(tmdsBlue));

    // Strobe the tmdsShiftLoad once every 10 tmdsClk
    // i.e. at the start of new pixel data
    reg [3:0] tmdsCounter10=0;
    reg tmdsShiftLoad=0;
    always @(posedge tmdsClk) begin
    if (~reset) begin
        tmdsCounter10 <= 0;
        tmdsShiftLoad <= 0;
    end else begin
        tmdsCounter10 <= (tmdsCounter10==4'd9) ? 4'd0 : tmdsCounter10+4'd1;
        tmdsShiftLoad <= (tmdsCounter10==4'd9);
    end
    end

    // Latch the TMDS colour values into three shift registers
    // at the start of the pixel, then shift them one bit each tmdsClk.
    // We will then output the LSB on each tmdsClk.
    reg [9:0] tmdsShiftRed=0, tmdsShiftGreen=0, tmdsShiftBlue=0;
    always @(posedge tmdsClk) begin
    if (~reset) begin
        tmdsShiftRed <= 0;
        tmdsShiftGreen <= 0;
        tmdsShiftBlue <= 0;
    end else begin
        tmdsShiftRed <= tmdsShiftLoad ? tmdsRed
            : {1'b0, tmdsShiftRed[9:1]};
        tmdsShiftGreen <= tmdsShiftLoad ? tmdsGreen
            : {1'b0, tmdsShiftGreen[9:1]};
        tmdsShiftBlue <= tmdsShiftLoad ? tmdsBlue
            : {1'b0, tmdsShiftBlue[9:1]};
    end
    end

    OBUFDS obufdsRed   (.I(tmdsShiftRed  [0]), .O(tmdsPos[2]), 
        .OB(tmdsNeg[2]));
    OBUFDS obufdsGreen (.I(tmdsShiftGreen[0]), .O(tmdsPos[1]), 
        .OB(tmdsNeg[1]));
    OBUFDS obufdsBlue  (.I(tmdsShiftBlue [0]), .O(tmdsPos[0]), 
        .OB(tmdsNeg[0]));
    OBUFDS obufdsClock (.I(pixelClk), .O(tmdsPosClk), .OB(tmdsNegClk));
endmodule
