module muse(
    input oscClk,
    // HDMI Output:
    // - [7:5] TMDS+ Data
    // - [4] TMDS+ Clock
    // - [3:1] TMDS- Data
    // - [0] TMDS- Clock
    output [7:0] hdmiOutput
);

// Generate a test pattern
// change screen bg color per 1s
reg [24:0] divCounter25M;
always @(posedge oscClk) begin
    divCounter25M <= (divCounter25M == 25'd25000000) ? 25'd0
        : divCounter25M+25'd1;
end

reg colorState;
always @(posedge oscClk) begin
    colorState <= (divCounter25M) ? colorState : (~colorState);
end

reg [23:0] bgColor;
always @(posedge oscClk) begin
    bgColor <= (colorState) ? {{8{1'b1}},{16{1'b0}}} 
        : {{16{1'b0}}, {8{1'b1}}};
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
    .tmdsNegClk(hdmiOutput[0])
);

endmodule
