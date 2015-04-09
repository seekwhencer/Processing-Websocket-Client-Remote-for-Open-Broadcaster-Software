/*
    The Beat Detection Auto Pilot
*/
public class BeatPilot {
  
  public boolean detection   = true;
  public String mode         = "source";
  
  public float tickLengthFrom = 0.1; 
  public float tickLengthTo   = 5;
  
  public int tickLast;
  public float tickLastSwitch;
  
  public String tickSource;
  public String tickScene;  
  
  public int countTickLo = 0;
  public int countTickMid = 0;
  public int countTickHi = 0;
  public int countTickSwitch = 0;
  
  public float msLo   = 0;
  public float msMid  = 0;
  public float msHi   = 0;
  
  public float msLoLast   = 0;
  public float msMidLast  = 0;
  public float msHiLast   = 0;

  public BeatPilot( ) {

  }
  
  
  /*
  *
  */
  public void switchBeatSource(int band) {
    
    if(this.detection==false)
      return;   

    switch (band) {
      case 1:
        this.countTickLo++;
        this.msLo = millis() - this.msLoLast;
        this.msLoLast = millis();
        break;
        
      case 2:
        this.countTickMid++;
        this.msMid = millis() - this.msMidLast;
        this.msMidLast = millis();
        break;
        
      case 3:
        this.countTickHi++;
        this.msHi = millis() - this.msHiLast;
        this.msHiLast = millis();
        break;
      
      
    }
    
    
    
    
    
    float diffTickLast = millis() - this.tickLast;
    float randMaxLast = random(this.tickLengthFrom, this.tickLengthTo)*1000;

    if (diffTickLast<randMaxLast)
      return;

    String source;
    String scene;

    if (this.mode=="source") {
      this.setRandomItem("source");
      source = this.tickSource;

      // sends the tick source to the web client
      if (s.openConnections>0)
        s.sendTick(source);

      c.sendSourceSwitch(source);

    }    
    
    if (obsRemoteSourceMode=="scene") {
      this.setRandomItem("scene");
      scene = this.tickScene;
      c.sendSceneSwitch(scene);
    }

    countTickSwitch++;
    this.tickLastSwitch =  diffTickLast;
    this.tickLast = millis();

    // draw the red tick box
    fill(255, 0, 0);
    rect((width/2), 10, (width/2)-10, 170);
  }
  
  
  
  /*
  *
  */
  public void setRandomItem( String mode ) {
    String item;

    if (mode=="source") {
      item = obsSources[int(random(obsSources.length))];      
      if (item==this.tickSource) {
        this.setRandomItem("source");
      } else {
        this.tickSource = item;
      }
    }

    if (mode=="scene") {
      item = obsScenes[int(random(obsScenes.length))];      
      if (item==this.tickScene) {
        this.setRandomItem("scene");
      } else {
        this.tickScene = item;
      }
    }
  }

}
