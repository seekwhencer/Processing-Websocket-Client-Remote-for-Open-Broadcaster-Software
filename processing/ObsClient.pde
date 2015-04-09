/*
    The Websocket Client for OBS Remote
*/
public class ObsClient extends WebSocketClient {

  public ObsClient( URI serverUri, Draft draft ) {
    super( serverUri, draft );
  }

  public ObsClient( URI serverURI ) {
    super( serverURI );
  }

  // the trigger
  public void switchObsSource() {
    float diffTickLast = millis() - obsTickLast;
    float randMaxLast = random(obsTickLengthFrom, obsTickLengthTo)*1000;
    String source;
    String scene;

    if (diffTickLast<randMaxLast)
      return;

    if (obsRemoteSourceMode=="source") {
      this.setRandomItem("source");
      source = obsTickSource;

      // sends the tick source to the web client
      if (openCmdConnections>0)
        s.sendTick(source);

      this.sendSourceSwitch(source);

    }    

    if (obsRemoteSourceMode=="scene") {
      this.setRandomItem("scene");
      scene = obsTickScene;
      this.sendSceneSwitch(scene);
    }

    tickSwitch++;
    obsTickLastSwitch =  diffTickLast;
    obsTickLast = millis();

    // draw the red tick box
    fill(255, 0, 0);
    rect((width/2), 10, (width/2)-10, 170);
  }
  
  
  //
  public void sendSourceSwitch(String source){
    c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+source+"\",\"render\":true}");
    obsTickSource = source;
    this.sendOffAllSources(source);
  }
  
  
  //
  public void sendSceneSwitch(String scene){
    c.send("{\"request-type\":\"SetCurrentScene\",\"scene-name\":\""+scene+"\"}");
    obsTickScene = scene;
  }


  // 
  public void setRandomItem(String mode) {
    String item;

    if (mode=="source") {
      item = obsSources[int(random(obsSources.length))];      
      if (item==obsTickSource) {
        this.setRandomItem("source");
      } else {
        obsTickSource = item;
      }
    }

    if (mode=="scene") {
      item = obsScenes[int(random(obsScenes.length))];      
      if (item==obsTickScene) {
        this.setRandomItem("scene");
      } else {
        obsTickScene = item;
      }
    }
  }

  
  //
  public void processResponse(String message) {
    JSONObject m = JSONObject.parse( message );

    // the current scene?
    if (m.hasKey("current-scene")) {
      obsCurrentScene = m.getString("current-scene");
    }

    // build scenes and sources
    if (m.hasKey("scenes")) {
      JSONArray scenes = m.getJSONArray("scenes");

      obsScenesList = new ArrayList<ObsScene>();

      for (int i=0; i<scenes.size (); i++) {
        JSONObject scene    = scenes.getJSONObject(i);
        JSONArray sources   = scene.getJSONArray("sources");
        String scene_name   = scene.getString("name");

        obsScenesList.add(i, new ObsScene(scene_name));

        ObsScene obsScene = obsScenesList.get(i);

        for (int ii=0; ii<sources.size (); ii++) {
          JSONObject source  = sources.getJSONObject(ii);
          String name   = source.getString("name");
          Boolean render = source.getBoolean("render");

          obsScene.addSource(name, render, ii);
        }
      }
    } // scenes & source stack build end
    
    
  }


  //turn all sources off
  public void sendOffAllSources(String source) {
    for (String i : obsSources) {
      if (i!=source) {
        c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+i+"\",\"render\":false}");
      }
    }
  }

  
  // request the actual scene and source list from OBS Remote
  public void getSceneList(){
    System.out.println( "ObsClient: get Scene List");
    c.send("{\"request-type\":\"GetSceneList\"}");
  }
  
  
  
  
  /*
      Overrides
      
  */
  @Override
  public void onOpen( ServerHandshake handshakedata ) {
    System.out.println( "ObsClient: opened connection to "+obsRemoteHost+" on port "+obsRemotePort );
    this.getSceneList();
  }

  @Override
  public void onMessage( String message ) {
    //System.out.println( "ObsClient: received " + message );
    this.processResponse(message);
  }

  @Override
    public void onClose( int code, String reason, boolean remote ) {
    System.out.println( "Connection closed by " + ( remote ? "remote peer" : "us" ) );
  }

  @Override
    public void onError( Exception ex ) {
    ex.printStackTrace();
    // if the error is fatal then onClose will be called additionally
  }
}
