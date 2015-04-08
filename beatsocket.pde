
import spacebrew.*;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.lang.reflect.Method;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.drafts.Draft_10;
import org.java_websocket.drafts.Draft_17;
import org.java_websocket.framing.Framedata;
import org.java_websocket.handshake.ServerHandshake;

import org.java_websocket.exceptions.InvalidHandshakeException;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.handshake.ClientHandshakeBuilder;

//import org.json.*; //https://github.com/agoransson/JSON-processing

// websocket server
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.util.Collection;
import org.java_websocket.WebSocket;
import org.java_websocket.WebSocketImpl;
import org.java_websocket.framing.Framedata;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

// minim
import ddf.minim.signals.*;//variois parts of the minim libary
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

import processing.core.PApplet;

// minim Setup
Minim minim;
AudioInput in;

//
BeatDetect beat;
BeatListener bl;

//
ObsClient c;
CommandServer s;
ArrayList<ObsScene> obsScenesList;

// use "source" or "scene"
String obsRemoteSourceMode = "source";

//
String obsRemoteHost  = "localhost";
String obsRemotePort  = "4444";
String obsRemoteUrl   = "ws://"+obsRemoteHost+":"+obsRemotePort;

String commandServerPort = "5555";

//
String[] obsSources = {
  "src1", "src2", "src3"
};

String[] obsScenes = { 
  "scn1", "scn2", "scn3", "scn4", "scn5"
};

String obsCurrentScene;



//
int obsTickLast;
float obsTickLastSwitch;
float obsTickLengthFrom = 0.1; 
float obsTickLengthTo = 5;
String obsTickSource;
String obsTickScene;


int tickLo = 0;
int tickMid = 0;
int tickHi = 0;
int tickSwitch = 0;

float msLo   = 0;
float msMid  = 0;
float msHi   = 0;

float msLoLast   = 0;
float msMidLast  = 0;
float msHiLast   = 0;

int openCmdConnections = 0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  size(600, 280);
  frameRate( 50 ); 
  noStroke();

  //
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 512); 

  beat = new BeatDetect(in.bufferSize(), in.sampleRate());
  beat.setSensitivity(300);
  bl = new BeatListener(beat, in);

  // init Obs Websocket Client
  c = new ObsClient( URI.create( obsRemoteUrl ), new Draft_obs() );
  c.connect();

  //init Websocket Command Server
  new ServerThread().start();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw() {
  textSize(14);
  stroke(0);

  //// 
  fill( 0, 0, 0, 100 );
  rect(0, 0, width, height);

  ////
  boolean kick    = beat.isKick();
  boolean hat     = beat.isHat();
  boolean snare   = beat.isSnare();

  if (kick == true) {
    fill(255, 255, 0);
    rect(10, 10, (width/2)-20, 50);
    tickLo++;
    msLo = millis() - msLoLast;
    msLoLast = millis();
    c.switchObsSource();
  }

  if (snare == true) {
    fill(255, 0, 255);
    rect(10, 70, (width/2)-20, 50);
    tickMid++;
    msMid = millis()-msMidLast;
    msMidLast = millis();
    c.switchObsSource();
  }


  if (hat == true) {
    fill(255);
    rect(10, 130, (width/2)-20, 50);
    tickHi++;
    msHi = millis()-msHiLast;
    msHiLast = millis();
    c.switchObsSource();
  }

  fill( 0, 0, 0, 100 );
  rect(10, 200, (width/2)-20, 30);
  fill (250);

  text("Lo "+tickLo+" ("+msLo/1000+" sec.)", 10, 200);
  text("Mid " +tickMid+" ("+msMid/1000+" sec.)", 10, 220);
  text("Hi "+tickHi+" ("+msHi/1000+" sec.)", 10, 240);
  text("Tick "+(tickSwitch)+" ("+(obsTickLastSwitch)/1000+" sec.)", 10, 260);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
void stop() {
  minim.stop();
  super.stop();
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
   Beat Listener
 */
class BeatListener implements AudioListener {
  private BeatDetect beat;
  private AudioInput source;

  BeatListener(BeatDetect beat, AudioInput source) {
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
  }

  void samples(float[] samps) {
    beat.detect(source.mix);
  }

  void samples(float[] sampsL, float[] sampsR) {
    beat.detect(source.mix);
  }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* 
 Open Broadcaster Connection Draft
 */
public class Draft_obs extends Draft_17 {
  @Override
    public ClientHandshakeBuilder postProcessHandshakeRequestAsClient( ClientHandshakeBuilder request ) {
    super.postProcessHandshakeRequestAsClient( request );
    request.put( "Sec-WebSocket-Version", "13" );
    request.put( "Sec-WebSocket-Protocol", "obsapi" ); // this is the important change
    return request;
  }
}


/////////  ///////////////////////////////////////////////////////////////////////////////////////////////////
/*
The Client
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

    if (diffTickLast<randMaxLast)
      return;

    if (obsRemoteSourceMode=="source") {
      this.setRandomItem("source");
      source = obsTickSource;

      // sends the source to the web client
      if (openCmdConnections>0)
        s.sendToAll("{\"source\":\""+source+"\"}");

      c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+source+"\",\"render\":true}");
      this.offObsSource(source);
    }    

    if (obsRemoteSourceMode=="scene") {
      this.setRandomItem("scene");
      source = obsTickScene;

      c.send("{\"request-type\":\"SetCurrentScene\",\"scene-name\":\""+source+"\"}");
    }

    tickSwitch++;
    obsTickLastSwitch =  diffTickLast;
    obsTickLast = millis();

    // draw the red box
    fill(255, 0, 0);
    rect((width/2), 10, (width/2)-10, 170);
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
    } // scenes end
  }

  //turn all sources off
  public void offObsSource(String source) {
    for (String i : obsSources) {
      if (i!=source) {
        c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+i+"\",\"render\":false}");
      }
    }
  }
  
  //
  public void getSceneList(){
    
    System.out.println( "ObsClient: get Scene List");
    c.send("{\"request-type\":\"GetSceneList\"}");
  }

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
    OBS Remote Scene
 */
public class ObsScene {

  public ArrayList<ObsSource> sources;
  private String name;

  public ObsScene( String name_ ) {
    this.name = name_;
    this.sources = new ArrayList<ObsSource>();
  }

  public void addSource(String name_, Boolean render_, int index_) {
    sources.add(index_, new ObsSource(name_, render_) );
  }

  public String getName() {
    return name;
  }

  public ObsSource getSource(int index_) {
    return sources.get(index_);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
    OBS Remote Source
 */
public class ObsSource {

  private String name = "";
  private Boolean render = true;

  public ObsSource( String name_, Boolean render_ ) {
    this.name = name_;
    this.render=render_;
  }

  public String getName() {
    return name;
  }

  public Boolean getRender() {
    return render;
  }
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
    Server Thread for Command Server
 */
public class ServerThread extends Thread {
  @Override
    public void run() {
    try {
      WebSocketImpl.DEBUG = false;
      int port = parseInt(commandServerPort); // 843 flash policy port
      try {
        port = Integer.parseInt( args[ 0 ] );
      } 
      catch ( Exception ex ) {
      }

      s = new CommandServer( port );
      s.start();
      System.out.println( "CommandServer: started on port " + s.getPort() );

      BufferedReader sysin = new BufferedReader( new InputStreamReader( System.in ) );
      while ( true ) {
        String in = sysin.readLine();
        s.sendToAll( in );
      }
    }
    catch(IOException e) {
      e.printStackTrace();
    }
  }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
    Command Server for Websocket HTML-Client
 */
public class CommandServer extends WebSocketServer {

  public CommandServer( int port ) {
    super( new InetSocketAddress( port ) );
  }
  public CommandServer( InetSocketAddress address ) {
    super( address );
  }

  @Override
  public void onOpen( WebSocket conn, ClientHandshake handshake ) {
    openCmdConnections++;
    //this.sendToAll( "CommandServer | new connection: " + handshake.getResourceDescriptor() );
    System.out.println( "CommandServer: "+conn.getRemoteSocketAddress().getAddress().getHostAddress() + " connected!" );
    
    c.getSceneList();
    this.sendCurrentScene();
    this.sendScenes();
    
  }

  @Override
    public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
    openCmdConnections--;
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
}
