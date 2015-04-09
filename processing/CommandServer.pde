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
    this.sendCurrentScene();
    this.sendScenes();
    
  }

  @Override
    public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
    this.openConnections--;
    System.out.println( "CommandServer: "+conn + " has left" );
  }

  @Override
    public void onMessage( WebSocket conn, String message ) {
    //this.sendToAll( message );
    System.out.println( conn + ": " + message );
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
  /**
   * Sends <var>text</var> to all currently connected WebSocket clients.
   *
   * @param text
   * The String to send across the network.
   * @throws InterruptedException
   * When socket related I/O errors occur.
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
  public void sendScenes() {
    String jsonCmd = "{";
    jsonCmd = jsonCmd + "\"current_scene\":\""+obsCurrentScene+"\",";
    jsonCmd = jsonCmd + "\"scenes\" : [ ";
    for (int i=0; i < obsScenesList.size (); i++) {
      String jc = "{";
      jc = jc + "\"name\" : \""+obsScenesList.get(i).getName()+"\" ";
      if (obsScenesList.get(i).sources.size()>0) {
        jc = jc + ", \"sources\" : [";
        for (int ii=0; ii < obsScenesList.get (i).sources.size(); ii++) {
          String source = obsScenesList.get(i).sources.get(ii).getName();
          Boolean render = obsScenesList.get(i).sources.get(ii).getRender();

          jc = jc + "{\"name\":\""+source+"\",\"render\":"+render+"}";
          if (ii<obsScenesList.get(i).sources.size()-1)
            jc = jc + ",";
        }
        jc = jc + "]";
        
      }
      jsonCmd = jsonCmd + jc;
      jsonCmd = jsonCmd + "}";
      if (i<obsScenesList.size()-1)
          jsonCmd = jsonCmd + ",";
    }
    jsonCmd = jsonCmd + "]}";
    this.sendToAll(jsonCmd);
  }
  
  /*
  *
  */
  public void sendCurrentScene(){
    this.sendToAll("{\"current_scene\":\""+obsCurrentScene+"\"}");
  }
  
  /*
  *
  */
  public void sendTick(String source){
    this.sendToAll("{\"source\":\""+source+"\"}"); // sending the Tick via CommandServer
  }
}
