   `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2018 07:09:01 PM
// Design Name: 
// Module Name: MxNmatrixMul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module NP_PM_MRmatrixMul(
    input clk,
    input reset,
    output accuF_m_bitwiseAnd
    );
 
    
    
 //  wire clkbA, clkaA, clkbB, clkaB ;
  /* wire  enaA=1,enaB=1,enbA=1,enbB=1,weaA=1,weaB=1 ;
   reg [7:0] addraA=0;
   reg [7:0]addrbA=0;
   reg [7:0]addraB=0;
   reg [31:0] dinaA=0,dinaB=0;
    
     assign  clkaA=clk,clkbA=clk,clkaB=clk,clkbB=clk ;
  */  
  
  reg [7:0]addrbA=0 ;
   reg [7:0]addrbB=0;
  reg [31:0] doutbA=0,doutbB=0;
   reg wrA_done=0,wrB_done=0 ; 
    reg count=0,countF=0;
   parameter N=2,P=4,M=3,R=5 ;
   
    

// 3rd given matrix performing ABD   A=N*P B=P*M  D=M*R


 /* wire clkbD, clkaD ;
   wire  enaD=1,enbD=1,weaD=1 ;
   reg [7:0] addraD=0;
   reg [31:0] dinaD=0;
 */   
  
   reg [7:0]addrbD=0;
   
  reg [31:0] doutbD=0;
   reg wrD_done=0 ;
   
   
   //-------------------------------------------------------------------
   
   // declare A and write values in A 
   wire [31:0]doutbA_w ;
   wire wrA_done_w ;
   
   defA memoryA(reset,clk,addrbA,doutbA_w,wrA_done_w);
   
   always@(*) begin 
   doutbA=doutbA_w ;
   wrA_done=wrA_done_w ;
   end
 
//-------------------------------------------------------------------

// declare B and write values in B later will be generated by randomness algorith 
wire [31:0]doutbB_w ;
wire wrB_done_w ;
wire [31:0]ran_w ;
defB memoryB(ran_w,reset,clk,addrbB,doutbB_w,wrB_done_w);

always@(*) begin 
doutbB=doutbB_w ;
wrB_done=wrB_done_w ;
end

//-------------------------------------------------------------------

// declare D and write values in D  
wire [31:0]doutbD_w ;
wire wrD_done_w ;

defD memoryD(reset,clk,addrbD,doutbD_w,wrD_done_w);

always@(*) begin 
doutbD=doutbD_w ;
wrD_done=wrD_done_w ;
end




//--------------------matrix ready sign --------
  // wire enaMul=0 ;
  // assign enaMul = wrA_done&wrB_done ;
reg enaMul=0 ;
always@(posedge clk&(~reset))
enaMul <= wrA_done&wrB_done;

// transitions of adderesses for Block RAM B to read values 
   
always@(negedge clk&enaMul&(~reset)) begin
   if(addrbB < P*M ) begin
      addrbB <=addrbB+ 1 ;
   end
   else if(addrbB==P*M) begin
   addrbB =1 ;
   count =count+1 ;
   end
   else 
     addrbB = 1;           //if used <= here severe error
end

always@(negedge clk&enaMul&(~reset)) begin
   if(addrbB < P*M) begin
      if(addrbA < (count+1)*P) begin
	  addrbA <= addrbA+1 ;
	  end
      else 
      addrbA <= count*P + 1 ;
   end
  /* else begin
    //count = count+1 ;
   //    addrbA=count*P + 1 ;
   //end */ 
     
     end
     
     //------------------------------------MULTIPLICATION----------------
     
 // multiplication start
 reg [5:0]count_p=6'b111111 ;                     //takes X to 0 as negedge 
 reg [31:0]accu_p=0 ;
 reg [31:0]dinaC=0 ;
 always@(negedge clk&enaMul&(~reset)) begin
    if(count_p < P) begin
     accu_p<= accu_p + doutbA*doutbB ;
     count_p <= count_p + 1 ;
     end
     else if(count_p==P) begin
      dinaC<=accu_p ;
      accu_p<=doutbA*doutbB ;
      count_p<=1 ;
     end
     else count_p=0 ;
 end
    
    
 //writing in Mem_C result of above two matrix
 reg [7:0] addraC=0 ;
 reg [7:0] addrbC=1 ;
 //reg [31:0] dinaC=0 ; already declared
 reg [31:0] doutbC=0 ;
 wire clkbC, clkaC ;
    wire  enaC=1,enbC=1,weaC=1 ;   
    reg wrC_done=0 ;
 assign clkaC=clk, clkbC=clk ;

//My BramC
reg [31:0]MEM_C[0:255] ;

always@(posedge clkaC&weaC&enaC&(~reset)&enaMul) begin
if(count_p==P) begin
    MEM_C[addraC] <= dinaC ;
    addraC <= addraC + 1 ;
    end
end

always@(posedge clkbC&enbC&(~reset)&enaMul) begin
doutbC <= MEM_C[addrbC] ;
end
 // MY bram C end

//check for write done
always@(negedge clkaC&enaC&(~reset)&enaMul) begin
if(addraC==(M*N+1)) begin
wrC_done=1 ;
end
end
    
// ----------------------------------------------prepare for 3rd matrix R multiplication-----------------------
reg enaMulF=0 ;
always@(posedge clk&(~reset))
enaMulF <= wrC_done&wrD_done;



// transitions of adderesses for Block RAM D to read values 
   
always@(negedge clk&enaMulF&(~reset)) begin
   if(addrbD < M*R ) begin
      addrbD <=addrbD+ 1 ;
   end
   else if(addrbD==M*R) begin
   addrbD =1 ;
   countF =countF+1 ;
   end
   else 
     addrbD = 1;           //if used <= here severe error
end

always@(negedge clk&enaMulF&(~reset)) begin
   if(addrbD < M*R) begin
      if(addrbC < (countF+1)*M) begin
	  addrbC <= addrbC+1 ;
	  end
      else 
      addrbC <= countF*M + 1 ;
   end
  /* else begin
    //count = count+1 ;
   //    addrbA=count*P + 1 ;
   //end */ 
     
     end
     
 //----------------------Final Multiplication-----------------------------------
 
      //------------------------------------MULTIPLICATION----------------
      
  // multiplication start
  reg [5:0]countF_m=6'b111111 ;                     //takes X to 0 as negedge 
  reg [31:0]accuF_m=0 ;
  reg [31:0]dinaF=0 ;
  always@(negedge clk&enaMulF&(~reset)) begin
     if(countF_m < M) begin
      accuF_m<= accuF_m + doutbC*doutbD ;
      countF_m <= countF_m + 1 ;
      end
      else if(countF_m==M) begin
       dinaF<=accuF_m ;
       accuF_m<=doutbC*doutbD ;
       countF_m<=1 ;
      end
      else countF_m=0 ;
  end
     
     
  //writing in MEM_F final result of above  matrices
  reg [7:0] addraF=0 ;
  reg [7:0] addrbF=1 ;
  //reg [31:0] dinaF=0 ; already declared
  reg [31:0] doutbF=0 ;
  wire clkbF, clkaF ;
     wire  enaF=1,enbF=1,weaF=1 ;   
     reg wrF_done=0 ;
  assign clkaF=clk, clkbF=clk ;
 
 //My BramF
 reg [31:0]MEM_F[0:255] ;
 
 always@(posedge clkaF&weaF&enaF&(~reset)&enaMulF) begin
 if(countF_m==M) begin
     MEM_F[addraF] <= dinaF ;
     addraF <= addraF + 1 ;
     end
 end
 
 always@(posedge clkbF&enbF&(~reset)&enaMulF) begin
 doutbF <= MEM_F[addrbF] ;
 end
  // MY bram F end
 
 //check for write done
 always@(negedge clkaF&enaF&(~reset)&enaMulF) begin
 if(addraF==(N*R+1)) begin
 wrF_done=1 ;
 end
 end
         
        
//initial begin
//   $monitor("clk=%b addraA=%d dinaA=%d addrbA=%d doutbA=%d",clk,addraA,dinaA,addrbA,doutbA);
//end
   
   assign accuF_m_bitwiseAnd=&accuF_m ;
  

// ---------------------------Resetting system---   
   always@(posedge clk) begin 
    if(reset==1) begin
    //addraA=0;
    addrbA=1;
    //addraB=0;
    addrbB=1;
    addraC=0;
    addrbC=1;
   // addraD=0;
    addrbD=1;
    addraF=0;
    addrbF=1;
    
    
  //  dinaA=0;
  //  dinaB=0;
    dinaC=0 ;
   // dinaD=0;
    dinaF=0;
    
    wrA_done=0 ;
    wrB_done=0;
    wrC_done=0 ;
    wrD_done=0 ;
    wrF_done=0;
    
    doutbA=0;
    doutbB=0;
    doutbC=0;
    doutbD=0;
    doutbF=0;
    
    count=0;
    countF=0;
        
    enaMul=0;    
    count_p=0;
    accu_p=0;
    //dinaC=0 ;
    
    enaMulF=0;
    countF_m=0;
    accuF_m=0;
    
   /* MEM_A[0]=0;
    MEM_A[1]=0;
        MEM_A[2]=0;
        MEM_A[3]=0;
            MEM_A[4]=0;
            MEM_A[5]=0;
                MEM_A[6]=0;
                MEM_A[7]=0;
                    MEM_A[8]=0;
                    MEM_A[9]=0;
                        MEM_A[10]=0;
                */                
    end
   end
    
   


   
endmodule


