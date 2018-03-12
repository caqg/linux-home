module top ();

   reg discard;
   integer duration;

   initial begin
      duration = 1000000;
      #0;
      if ($test$plusargs("DURATION")) begin
         discard = $value$plusargs("DURATION=%d", duration);
         $display("Duration given as %d", duration);
      end else begin
         $display("Duration defaulted to %d", duration);
      end
   end

endmodule

// compile by "iverilog plus-duration.cpp -o plus-duration.sim"
// run as "./plus-duration.sim" for default
// run as "./plus-duration.sim +DURATION=9999999" for override
// run as "vvp <vvpflags> plus-duration.sim <etc>" to pass vvp flags
