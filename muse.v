module muse(
    input oscClk,
    // HDMI Output:
    // - [7:5] TMDS+ Data
    // - [4] TMDS+ Clock
    // - [3:1] TMDS- Data
    // - [0] TMDS- Clock
    output [7:0] hdmiOutput
);

//reg [24:0] clk_1Hz;
//always @(posedge oscClk) begin
//    clk_1Hz <= (clk_1Hz == 25'd25000000) ? 25'd0
//        : clk_1Hz+25'd1;
//end

wire [9:0] hdmiScreenX, hdmiScreenY;
wire square;
reg [23:0] bgColor;
always @(posedge oscClk) begin
    square <= (hdmiScreenX > 220 && hdmiScreenX < 420) && (hdmiScreenY > 140 && hdmiScreenY < 340);
end
always @(posedge oscClk) begin
    bgColor <= {(square)? 4'hf:4'h1, (square)? 4'hf:4'h3, 
        (square)? 4'hf:4'h5};
end

wire hdmiClk_25M, hdmiClk_250M;
clock systemClk(
    .clkin_25MHz(oscClk),
    .clk_25MHz(hdmiClk_25M),
    .clk_250MHz(hdmiClk_250M)
);

hdmiController hdmiCtrl(
    .reset(1'b1),
    .pixelClk(hdmiClk_25M),
    .tmdsClk(hdmiClk_250M),
    .vgaRed(bgColor[23:16]),
    .vgaGreen(bgColor[15:8]),
    .vgaBlue(bgColor[7:0]),
    .tmdsPos(hdmiOutput[7:5]),
    .tmdsPosClk(hdmiOutput[4]),
    .tmdsNeg(hdmiOutput[3:1]),
    .tmdsNegClk(hdmiOutput[0]),
    .screenX(hdmiScreenX),
    .screenY(hdmiScreenY)
);

endmodule
