/*
    The Websocket Client for OBS Remote
*/
public class ObsClient extends WebSocketClient {

  public boolean debug_message = false;
  public int openConnections = 0;
  
  public ObsClient( URI serverUri, Draft draft ) {
    super( serverUri, draft );
  }

  public ObsClient( URI serverURI ) {
    super( serverURI );
  }

  
  //
  public void sendSourceSwitch(String source){
    c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+source+"\",\"render\":true}");
    bp.tickSource = source;
    this.sendOffAllSources(source);
  }
  
  public void sendSourceRender(String source, boolean render){
    c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+source+"\",\"render\":"+render+"}");
  }
  
  
  //
  public void sendSceneSwitch(String scene){
    c.send("{\"request-type\":\"SetCurrentScene\",\"scene-name\":\""+scene+"\"}");
    bp.tickScene = scene;
  }


  
  //
  public void processResponse(String message) {
    JSONObject m = JSONObject.parse( message );

    // the current scene?
    if (m.hasKey("current-scene")) {
      bp.currentScene = m.getString("current-scene");
    }
    
    // get obs changes
    if(m.hasKey("update-type")){      
      
      // scene changed
      if(m.hasKey("scene-name")){
        bp.currentScene = m.getString("scene-name");
        this.getSceneList();
        s.sendScenes("when scene in obs changed");
      }
      
      // source changed
      if(m.hasKey("source-name")){
        JSONObject source = m.getJSONObject("source");
        bp.setSourceRender(bp.currentScene, m.getString("source-name"), source.getBoolean("render"));
        //s.sendScenes();
      }
      
      // scene changed, order
      String update_type = m.getString("update-type");
      if(update_type.equals("ScenesChanged") || update_type.equals("RepopulateSources") || update_type.equals("SourceOrderChanged") ){
        this.getSceneList();
      }
      
    }

    // build scenes and sources
    if (m.hasKey("scenes")) {
      JSONArray scenes = m.getJSONArray("scenes");
      
      if(bp.obsScenesList == null ){
        bp.obsScenesList = new ArrayList<ObsScene>();
        
        for (int i=0; i<scenes.size (); i++) {
          JSONObject scene    = scenes.getJSONObject(i);
          String scene_name   = scene.getString("name");
          bp.obsScenesList.add(i, new ObsScene(scene_name));
          ObsScene obsScene = bp.obsScenesList.get(i);
          
          JSONArray sources   = scene.getJSONArray("sources");  
          for (int ii=0; ii<sources.size (); ii++) {
            JSONObject source  = sources.getJSONObject(ii);
            String name   = source.getString("name");
            Boolean render = source.getBoolean("render");
  
            obsScene.addSource(name, render, ii);
          }
        }
      } else {
        // merge :)
        
        ArrayList<ObsScene> obsScenesList = new ArrayList<ObsScene>();
        
        for (int i=0; i<scenes.size(); i++) {
          JSONObject scene    = scenes.getJSONObject(i);
          String scene_name   = scene.getString("name");
          obsScenesList.add(i, new ObsScene(scene_name));
          ObsScene obsScene   = obsScenesList.get(i);
          ObsScene obsSceneMatch = bp.getSceneByName(scene_name); // <--
          
          if(obsSceneMatch!=null){
            obsScene.detection = obsSceneMatch.detection;
            obsScene.tickLengthFrom = obsSceneMatch.tickLengthFrom;
            obsScene.tickLengthTo = obsSceneMatch.tickLengthTo;
          }
          
          JSONArray sources   = scene.getJSONArray("sources");  
          for (int ii=0; ii<sources.size (); ii++) {
            JSONObject source  = sources.getJSONObject(ii);
            String name   = source.getString("name");
            boolean render = source.getBoolean("render");
            obsScene.addSource(name, render, ii);
            
            ObsSource obsSource = obsScene.sources.get(ii);
            ObsSource obsSourceMatch = obsSceneMatch.getSourceByName(name); // <--
            
            if(obsSourceMatch!=null){
              obsSource.render = obsSourceMatch.render;
              obsSource.beat = obsSourceMatch.beat;
            }
          }
        }
        
        //if(obsScenesList!=null){
          bp.obsScenesList = obsScenesList;
          s.sendScenes("after obs scene update merge");
        //}
        
      }
    } // scenes & source stack build end
    
    
    
  }


  //turn all sources off
  public void sendOffAllSources(String source) {
    ObsScene currentScene =  bp.getCurrentScene();
    for (int i=0; i<currentScene.sources.size(); i++) {
      if (! currentScene.sources.get(i).name.equals(source) &&  currentScene.sources.get(i).getBeat()==true ) {
        c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+currentScene.sources.get(i).name+"\",\"render\":false}");
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
    this.openConnections++;
    System.out.println( "ObsClient: opened connection to "+obsRemoteHost+" on port "+obsRemotePort );
    this.getSceneList();
  }

  @Override
  public void onMessage( String message ) {
    if(debug_message==true)
      System.out.println( "ObsClient: received " + message );
    
    this.processResponse(message);
  }

  @Override
  public void onClose( int code, String reason, boolean remote ) {
    this.openConnections--;
    System.out.println( "Connection closed by " + ( remote ? "remote peer" : "us" ) );
  }

  @Override
  public void onError( Exception ex ) {
    ex.printStackTrace();
    this.openConnections--;
    // if the error is fatal then onClose will be called additionally
  }
}
