
 add_fsm_encoding \
       {SpiCtrl.current_state} \
       { }  \
       {{000 000} {001 001} {010 010} {011 011} {100 100} {101 101} {110 110} {111 111} }

 add_fsm_encoding \
       {Delay.current_state} \
       { }  \
       {{00 00} {01 01} {10 10} {11 11} }
