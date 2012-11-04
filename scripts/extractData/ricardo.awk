BEGIN { 
 # some variables to keep important values 
 tSent_ = 0; 
 tRecv_ = 0; 
 startTime_ = 0; 
 endTime_ = 0; 
  
 # end file used to put the relevant information 
 #printf("\nDelivering packages taxe:\n") > "r1.dat"; 
 printf("") > "r1-time.txt"; 
} 
{ 
 # take the relevant information from trace files 
 event_ = $1; 
 time_ = $2; 
 type_ = $4; 
 pktType_ = $7; 

 # take the time between the first last packet – total run time 
 if (startTime_ > time_ || startTime_ == 0) 
  startTime_ = time_; 

 if (endTime_ < time_) 
  endTime_ = time_; 

 # sent 
 if (event_ == "s" && type_ != "RTR") { 
  tSent_++; 
  tSentTime_[int(time_/10)]++; 
 } 

 # received 
 else if (event_ == "r" && type_ != "RTR") { 
  tRecv_++; 
  tRecvTime_[int(time_/10)]++; 
 } 

} 

END { 
 runTime_ = endTime_ - startTime_; 
 blocks_ = int(runTime_/10); 
 #printf("\ntime  sent  recv\n") >> "r1.dat"; 
 sSent_ = 0; 
 sRecv_ = 0; 107
 for (b_ = 0; b_ <= blocks_+1; b_++) { 
  sSent_ += tSentTime_[b_]; 
  sRecv_ += tRecvTime_[b_]; 
  printf("%d\n", int((tRecvTime_[b_]/tSentTime_[b_])*100)) > "r1-time.txt"; 

 } 

 printf("%d\n", tSent_) >> "tSent.txt"; 
 printf("%d\n", tRecv_) >> "tRecv.txt"; 

}
