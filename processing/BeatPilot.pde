/*
    The Beat Detection Auto Pilot
*/
public class BeatPilot {
  
  public boolean detection   = true;
  public String mode         = "source";
  
  public String currentScene;
  public String currentSource; 

/*  
  public String[] sources = {
    "src1", "src2", "src3"
  };

  public String[] scenes = { 
    "scn1", "scn2", "scn3", "scn4", "scn5"
  };
*/  
  public ArrayList<ObsScene> obsScenesList;
  
  public float tickLengthFrom = 0.3; 
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

    // breaks
    if (diffTickLast<randMaxLast)
      return;


    if (this.mode=="source") {
      this.setRandomItem("source");
      this.currentSource = this.tickSource;

      // sends the tick source to the web client
      if (s.openConnections>0)
        s.sendTick(this.currentSource);

      c.sendSourceSwitch(this.currentSource);

    }    
    
    if (this.mode=="scene") {
      this.setRandomItem("scene");
      this.currentScene = this.tickScene;
      c.sendSceneSwitch(this.currentScene);
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

    if (mode=="source") {
      ObsScene scene = this.getCurrentScene(); 
      ObsSource source = scene.sources.get(int(random(scene.sources.size())));
      
      if(scene.countBeatSources()>1){
        if (source.name.equals(this.tickSource) || source.beat==false) { // exclude again the same and other not beat sources
          this.setRandomItem("source"); // set recursive
        } else {
          this.tickSource = source.name;
        }
      }
    }

    if (mode=="scene") {
      ObsScene scene = this.obsScenesList.get(int(random(this.obsScenesList.size())));
      
      if(this.countBeatScenes()>1){
        if (scene.name.equals(this.tickScene) || scene.beat==false) {
          this.setRandomItem("scene");
        } else {
          this.tickScene = scene.name;
        }
      }
    }
  }
  
  /*
  *
  */
  public void setSourceRender(String scene, String source, boolean render){
    for(int i=0; i<bp.obsScenesList.size(); i++){      
      ObsScene obsScene = bp.obsScenesList.get(i);
      if(obsScene.name.equals(scene)){
        for(int ii=0; ii<obsScene.sources.size(); ii++){
          ObsSource obsSource = obsScene.sources.get(ii);
          if(obsScene.sources.get(ii).name.equals(source)){
            obsSource.render = render;
            if(render==true)
              this.currentSource = source;
              
            return; 
          }
        }
      }     
    }
  }
  
  
  /*
  *
  */
  public ObsScene getCurrentScene(){
    for(int i=0; i<this.obsScenesList.size(); i++){
      ObsScene obsScene = bp.obsScenesList.get(i);
        if(obsScene.name.equals(this.currentScene)){
          return obsScene; 
        }
    }
    return new ObsScene("empty");
  }
  
  /*
  *
  */
  public ObsSource getCurrentSource(){
    ObsScene currentScene = this.getCurrentScene();
    for(int i=0; i<currentScene.sources.size(); i++){
      if(currentScene.sources.get(i).name.equals(this.currentSource)){
        return currentScene.sources.get(i);
      }
    }
    return new ObsSource("empty",false);
  }
  
  /*
  *
  */
  public void toggleSource(String name){
    ObsScene currentScene = this.getCurrentScene();
    ObsSource source = currentScene.getSourceByName(name);
    switch (int(source.render)) {
      case 1: source.render=false; break;
      case 0: source.render=true;  break;
    }
    c.sendSourceRender(source.name,source.render);
  }
  
  /*
  *
  */
  public void toggleBeatSource(String name){
    ObsScene currentScene = this.getCurrentScene();
    ObsSource source = currentScene.getSourceByName(name);
    switch (int(source.beat)) {
      case 1: source.beat=false; break;
      case 0: source.beat=true; break;
    }
  }
  
  /*
  *
  */
  public void toggleScene(String name){
    ObsScene scene = this.getSceneByName(name);
    this.currentScene = scene.name;
    this.tickScene = scene.name;
    c.sendSceneSwitch(scene.name);
  }
  
  /*
  *
  */
  public ObsScene getSceneByName(String name){
    for(int i=0; i<this.obsScenesList.size(); i++){
      if(this.obsScenesList.get(i).name.equals(name)){
        return this.obsScenesList.get(i);
      }
    }
    return new ObsScene("empty");
  }
  
  
  /*
  *
  */
   public int countBeatScenes(){
    int count = 0;
    for(int i=0; i<this.obsScenesList.size(); i++){
      if(this.obsScenesList.get(i).beat==true){
        count++;
      }
    }
    return count;
  }
  
}
