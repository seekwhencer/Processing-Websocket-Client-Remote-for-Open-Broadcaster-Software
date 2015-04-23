/*
    Command Server for Websocket HTML-Client
*/
public class CommandServer extends WebSocketServer {
  
  public int openConnections;
  
  public CommandServer( int port ) {
    super( new InetSocketAddress( port ) );
  }
  public CommandServer( InetSocketAddress address ) {
    super( address );
  }

  @Override
  public void onOpen( WebSocket conn, ClientHandshake handshake ) {
    this.openConnections++;
    //this.sendToAll( "CommandServer | new connection: " + handshake.getResourceDescriptor() );
    System.out.println( "CommandServer: "+conn.getRemoteSocketAddress().getAddress().getHostAddress() + " connected!" );
    
    c.getSceneList();
    //this.sendCurrentScene();
    //this.sendScenes("after login");
    
  }

  @Override
    public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
    this.openConnections--;
    System.out.println( "CommandServer: "+conn + " has left" );
  }

  @Override
    public void onMessage( WebSocket conn, String message ) {
      System.out.println("Command Server: "+conn + ": " + message );
      this.processMessage(message, conn);
    //this.sendToAll( message );
   
  }

  /*@Override
   public void onFragment( WebSocket conn, Framedata fragment ) {
   System.out.println( "received fragment: " + fragment );
   }
   */

  @Override
    public void onError( WebSocket conn, Exception ex ) {
    ex.printStackTrace();
    if ( conn != null ) {
      // some errors like port binding failed may not be assignable to a specific websocket
    }
  }
  
  /*
  *
  */
  public void processMessage(String message, WebSocket conn){
    JSONObject m = JSONObject.parse( message );
    
    if (m.hasKey("toggle-beat-source")) {
      bp.toggleBeatSource(m.getString("toggle-beat-source"));
      this.sendScenes("when beat source toggled");
    }
    
    if (m.hasKey("toggle-source")) {
      bp.toggleSource(m.getString("toggle-source"));
      this.sendScenes("when a source toggled");
    }
    
    if (m.hasKey("toggle-scene")) {
      bp.toggleScene(m.getString("toggle-scene"));
        this.sendScenes("when a scene toggled");
    }
    
    if (m.hasKey("change-range")) {
      bp.changeRange(m.getJSONObject("change-range"));
    }
    
    if (m.hasKey("toggle-scene-detection")) {
      bp.toggleSceneDetection(m.getString("toggle-scene-detection"));
      this.sendScenes("when the scene beat detection toggled");
      
    }
    
    if (m.hasKey("facebook-object-id")) {
      bp.facebookObjectId = m.getString("facebook-object-id");
      this.sendFacebookObjectId();
    }
    
  }

  /*
  *
  */
  public void sendToAll( String text ) {
    Collection<WebSocket> con = connections();
    synchronized ( con ) {
      for ( WebSocket ws : con ) {
        ws.send( text );
      }
    }
  }


  /*
  *
  */
  public void sendScenes(String use) {
    String jsonCmd = "{";
    jsonCmd = jsonCmd + "\"current_scene\":\""+bp.currentScene+"\",";
    
    jsonCmd = jsonCmd + "\"scenes\" : [ ";
    for (int i=0; i < bp.obsScenesList.size (); i++) {
      String jc = "{";
      jc = jc + "\"name\" : \""+bp.obsScenesList.get(i).getName()+"\", ";
      jc = jc + "\"detection\" : "+bp.obsScenesList.get(i).detection  +", ";
      jc = jc + "\"range\" : {\"from\":"+bp.obsScenesList.get(i).tickLengthFrom+",\"to\":"+bp.obsScenesList.get(i).tickLengthTo+"} ";
      if (bp.obsScenesList.get(i).sources.size()>0) {
        jc = jc + ", \"sources\" : [";
        for (int ii=0; ii < bp.obsScenesList.get (i).sources.size(); ii++) {
          String source = bp.obsScenesList.get(i).sources.get(ii).getName();
          Boolean render = bp.obsScenesList.get(i).sources.get(ii).getRender();
          Boolean beat = bp.obsScenesList.get(i).sources.get(ii).getBeat();
          
          jc = jc + "{\"name\":\""+source+"\",\"render\":"+render+",\"beat\":"+beat+"}";
          if (ii<bp.obsScenesList.get(i).sources.size()-1)
            jc = jc + ",";
        }
        jc = jc + "]";
        
      }
      jsonCmd = jsonCmd + jc;
      jsonCmd = jsonCmd + "}";
      if (i<bp.obsScenesList.size()-1)
          jsonCmd = jsonCmd + ",";
    }
    jsonCmd = jsonCmd + "]";
    jsonCmd = jsonCmd + "}";
    this.sendToAll(jsonCmd);
    System.out.println("Command Server: send Scenes "+use );
  }
  
  /*
  *
  */
  public void sendCurrentScene(){
    this.sendToAll("{\"current_scene\":\""+bp.currentScene+"\"}");
  }
  
  /*
  *
  */
  public void sendTick(String source){
    this.sendToAll("{\"source\":\""+source+"\"}"); // sending the Tick via CommandServer
  }
  
  /*
  *
  */
  public void sendFacebookObjectId(){
    this.sendToAll("{\"facebook_object_id\":\""+bp.facebookObjectId+"\"}"); 
  }
}
