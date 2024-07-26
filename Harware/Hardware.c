#include <String.h>
#include <LiquidCrystal.h>
LiquidCrystal lcd(2, 3, 4, 5, 6, 7 );  //RS,EN,D4,D5,D6,D7

#include "DHT.h"          //include DHT library
#define DHTPIN 10         //define as DHTPIN the Pin 3 used to connect the Sensor
#define DHTTYPE DHT11     //define the sensor used(DHT11)
DHT dht(DHTPIN, DHTTYPE); //create an instance of DHT

int i=0,temp=0,j=0;
int h,t;
int temperature, humidity, soil,ldr,rain,thur;
int w=0;
int phase11,phase22,phase33;
int s=0;
int BUZZER = A1; 
int MOTOR1 = 8; 
int FAN    = 9; 
int MOTOR  = A0; 
int count=0;
int phase1 = 11;
int phase2 = 12;
int phase3 = 13;
int rain2 = A2;
int soil2 = A3;
int thur2 = A4;
int ldr2  = A5;

int a1 =0;
int b1 =0;
int c1 =0;
int d1 =0;
int e1 =0;
int f1 =0;
int g1 =0;
int h1 =0;
int i1 =0;




 
void setup()
{
  Serial.begin(9600);
  dht.begin();
  digitalWrite(MOTOR1,LOW); 
  digitalWrite(FAN, LOW);
  digitalWrite(MOTOR, LOW); 
  lcd.begin(16,2);
  lcd.setCursor(5,0);
 // lcd.print("          ");
  lcd.setCursor(3,1);
  lcd.print("GREEN HOUSE    ");
  delay(1000);
  
  
  pinMode(phase1, INPUT); 
  pinMode(phase2, INPUT); 
  pinMode(phase3, INPUT);  
  
  pinMode(FAN, OUTPUT); 
  pinMode(MOTOR1, OUTPUT); 
  pinMode(MOTOR, OUTPUT);   
  
    // set up the digital pins to control
  delay(4000); // give time to log on to network.
  Serial.print("AT+CMGF=1 \r"); // set SMS mode to text
  delay(100);
  Serial.print("AT+CNMI=2,2,0,0,0 \r");
  // blurt out contents of new SMS upon receipt to the GSM shield’s serial out
  delay(1000);
  lcd.clear();
}
 

 
void loop()
//=====================================FIRST WHILE===================================================================================================//
 {
  {
 
while(count<500)
{
  
  digitalWrite(MOTOR1, LOW);
  h = dht.readHumidity();    // reading Humidity 
  t = dht.readTemperature(); // read Temperature as Celsius (the default)
  // check if any reads failed and exit early (to try again).
    if (isnan(h) || isnan(t)) 
    {    
    Serial.println("Failed to read from DHT sensor!");
    return;
    }
    phase11  = digitalRead(phase1);
    phase22  = digitalRead(phase2);
    phase33  = digitalRead(phase3);
    
    rain = analogRead(rain2);
    soil = analogRead(soil2);
    thur = analogRead(thur2);
    ldr  = analogRead(ldr2);
    
 
           
  
  lcd.setCursor(0,0); lcd.print("T:"); lcd.setCursor(2,0);  lcd.print(t);
  lcd.setCursor(5,0); lcd.print("H:"); lcd.setCursor(7,0); lcd.print(h);
  lcd.setCursor(10,0); lcd.print("F:");lcd.setCursor(12,0); lcd.print(thur);
  lcd.setCursor(0,1); lcd.print("So:"); lcd.setCursor(3,1); lcd.print(soil);   
  lcd.setCursor(8,1); lcd.print("RA:"); lcd.setCursor(12,1); lcd.print(rain);   
  
   
   
  if(t>=35)
  {
    
  Serial.println("TEMP HIGH");
  digitalWrite(FAN, HIGH); 
  
  // Serial.println("TEMP HIGH");
  digitalWrite(FAN, HIGH); 
  
    if(a1==0)
{
             Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("TEMPRATURE IS HIGH"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              a1=1;
}
  
  }
  else
  {
   a1=0;
  digitalWrite(FAN, LOW);
  }

  if(thur<=400)
  {
     digitalWrite(MOTOR1, HIGH);
     if( b1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
            Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("FIRE DETECTED"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              b1=1;
}
 
  
  }
  else
  {
   b1=0;
  digitalWrite(MOTOR1, LOW);
  }
  
  
  if(soil>=500)
  {
  digitalWrite(MOTOR, HIGH); 
   if( c1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
     
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("SOIL DRY"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              c1=1;
}
  }
  else
  {
    c1=0;
    digitalWrite(MOTOR, LOW); 
  }

  
    if(rain<500)
  {
   
    digitalWrite(BUZZER, HIGH); 
   if( f1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
            
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("RAIN DETECTED"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              f1=1;
}
  }
  else
  {
   
    digitalWrite(BUZZER, LOW); 
  }
  
  if(ldr>=700 && ldr<=1023)
  {
     if( d1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
             
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("LIGHT INTENSITY LOW"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              d1=1;
}
    
      
  }
  else
  if(ldr>=400 && ldr<=700)
  {
     if( e1 == 0)
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
             
              Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("LIGHT INTENSITY MEDIUM"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              e1=1;
}
      
  }
  else
  {
     if( i1 == 0 )
{
              Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
          
            Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("LIGHT INTENSITY HIGH"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              i1=1;
}
      
  }
        
  

  
  if(phase11==0 && phase22==0 && phase33==0)
  {
     if( g1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("3 PHASE IS AVAILABLE"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              g1=1;
}

  }
  else
  {
   if( h1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
            
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("3 PHASE IS NOT AVAILABLE"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              h1=1;
}
  }
  count++;
  }
  count=0;
  lcd.clear();
  }

 
 
//=====================================SECOUND  WHILE===================================================================================================//
 while(count<500)
  {
  digitalWrite(MOTOR1, LOW);
  h = dht.readHumidity();    // reading Humidity 
  t = dht.readTemperature(); // read Temperature as Celsius (the default)
  // check if any reads failed and exit early (to try again).
    if (isnan(h) || isnan(t)) 
    {    
    Serial.println("Failed to read from DHT sensor!");
    return;
    }
    phase11  = digitalRead(phase1);
    phase22  = digitalRead(phase2);
    phase33  = digitalRead(phase3);
    
    rain = analogRead(rain2);
    soil = analogRead(soil2);
    thur = analogRead(thur2);
    ldr  = analogRead(ldr2);

   
  if(t>=35)
  {
    
  Serial.println("TEMP HIGH");
  digitalWrite(FAN, HIGH); 
  
  // Serial.println("TEMP HIGH");
  digitalWrite(FAN, HIGH); 
  
    if(a1==0 )
{
             Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
               Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("TEMPRATURE IS HIGH"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              a1=1;
}
  
  }
  else
  {
   a1=0;
  digitalWrite(FAN, LOW);
  }

  if(thur<=400)
  {
     digitalWrite(MOTOR1, HIGH);
     if( b1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("FIRE DETECTED"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              b1=1;
}
 
  
  }
  else
  {
   b1=0;
  digitalWrite(MOTOR1, LOW);
  }
  
  
  if(soil>=500)
  {
  digitalWrite(MOTOR, HIGH); 
   if( c1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
     
           Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("SOIL DRY"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              c1=1;
}
  }
  else
  {
    c1=0;
    digitalWrite(MOTOR, LOW); 
  }

  
    if(rain<500)
  {
   
    digitalWrite(BUZZER, HIGH); 
   if( f1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
            
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("RAIN DETECTED"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              f1=1;
}
  }
  else
  {
   f1=0;
    digitalWrite(BUZZER, LOW); 
  }
  
  if(ldr>=700 && ldr<=1023)
  {i1=0;
     lcd.setCursor(0,0); lcd.print("LIGHT INT--LOW--");
      if( d1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
             
          Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("LIGHT INTENSITY LOW"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              d1=1;
}
     
  }
  else
  if(ldr>=400 && ldr<=700)
  {
    d1=0;
 
   lcd.setCursor(0,0); lcd.print("LIGHT INT MEDIUM");

     if( e1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
             
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("LIGHT INTENSITY MEDIUM"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              e1=1;
}
      
  }
 
  else
  {e1=0;
    lcd.setCursor(0,0); lcd.print("LIGHT INT--HIGH-");
    if( i1 == 0 )
{
              Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
          
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("LIGHT INTENSITY HIGH"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              i1=1;
}
      
  }

   if(phase11==0 && phase22==0 && phase33==0)
  {
    lcd.setCursor(0,1); 
    lcd.print("3-Q AVAILABLE");
     if( g1 == 0)
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
       
              delay(200);
             Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("3 PHASE AVAILABLE"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              g1=1;
}

  }
  else
  {
     lcd.setCursor(0,1); 
    lcd.print("3-Q NOT AVAILABLE");
    if( h1 == 0 )
{
           Serial.print("AT\r");
              delay(200);
              Serial.print("AT+CMGF=1\r");
              delay(200);
              Serial.print("AT+CNMI=2,2,0,0,0\r");
              delay(200);
              Serial.print("AT+CMGS=");
              delay(200);
              Serial.print('"');
              delay(200);
            Serial.print("9019717544");
              delay(200);
              Serial.print('"');
              delay(200);
              Serial.write(0x0D);
              delay(200);
              Serial.println("3 PHASE IS NOT AVAILABLE"); 
              delay(200);
              Serial.write(0x1A);
              delay(200);
              h1=1;
}
  }

  count++;
  }
  count=0;
  lcd.clear();
 }