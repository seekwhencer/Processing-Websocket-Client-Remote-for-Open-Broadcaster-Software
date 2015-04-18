import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import napplet.*; 
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
import ddf.minim.signals.*; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 
import ddf.minim.effects.*; 
import processing.core.PApplet; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class beatsocket extends PApplet {




















// websocket server












// minim
//variois parts of the minim libary






// minim Setup
Minim minim;
AudioInput in;

//
BeatDetect beat;
BeatListener bl;

//
ObsClient c;
CommandServer s;
BeatPilot bp;


//
String obsRemoteHost  = "localhost";
String obsRemotePort  = "4444";
String obsRemoteUrl   = "ws://"+obsRemoteHost+":"+obsRemotePort;

String commandServerPort = "5555";


////////////////////////////////////////////////////////////////////////////////////////////////////////////
public void setup() {
  size(600, 280);
  frameRate( 50 ); 
  noStroke();
  
  NAppletManager nappletManager = new NAppletManager(this);
  
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
  
  //
  bp = new BeatPilot();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
public void draw() {
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
    
    bp.switchBeatSource(1);
  }

  if (snare == true) {
    fill(255, 0, 255);
    rect(10, 70, (width/2)-20, 50);
    
    bp.switchBeatSource(2);
  }


  if (hat == true) {
    fill(255);
    rect(10, 130, (width/2)-20, 50);
    
    bp.switchBeatSource(3);
  }

  fill( 0, 0, 0, 100 );
  rect(10, 200, (width/2)-20, 30);
  fill (250);

  text("Lo "+bp.countTickLo+" ("+bp.msLo/1000+" sec.)", 10, 200);
  text("Mid " +bp.countTickMid+" ("+bp.msMid/1000+" sec.)", 10, 220);
  text("Hi "+bp.countTickHi+" ("+bp.msHi/1000+" sec.)", 10, 240);
  text("Tick "+(bp.countTickSwitch)+" ("+(bp.tickLastSwitch)/1000+" sec.)", 10, 260);
  
  text("Current Scene: "+bp.currentScene, (width/2)+10, 200);
  text("Current Source: "+bp.currentSource, (width/2)+10, 220);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
public void stop() {
  minim.stop();
  super.stop();
}
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

  public void samples(float[] samps) {
    beat.detect(source.mix);
  }

  public void samples(float[] sampsL, float[] sampsR) {
    beat.detect(source.mix);
  }
}
/*
    The Beat Detection Auto Pilot
*/
public class BeatPilot {
  
  public boolean detection   = true;
  public String mode         = "source";
  
  public String currentScene;
  public String currentSource; 
 
  public ArrayList<ObsScene> obsScenesList;
  
//  public float tickLengthFrom = 0.3; 
//  public float tickLengthTo   = 5;
  
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
    
    ObsScene current_scene = this.getCurrentScene();
    
    if(current_scene.detection==false)
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
    float randMaxLast = random(current_scene.tickLengthFrom, current_scene.tickLengthTo)*1000;

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
      ObsSource source = scene.sources.get(PApplet.parseInt(random(scene.sources.size())));
      
      if(scene.countBeatSources()>1){
        if (source.name.equals(this.tickSource) || source.beat==false) { // exclude again the same and other not beat sources
          this.setRandomItem("source"); // set recursive
        } else {
          this.tickSource = source.name;
        }
      }
    }

    if (mode=="scene") {
      ObsScene scene = this.obsScenesList.get(PApplet.parseInt(random(this.obsScenesList.size())));
      
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
    switch (PApplet.parseInt(source.render)) {
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
    switch (PApplet.parseInt(source.beat)) {
      case 1: source.beat=false; break;
      case 0: source.beat=true; break;
    }
  }
  
  /*
  *
  */
  public void toggleScene(String name){
    this.currentScene = name;
    this.tickScene = name;
    c.sendSceneSwitch(name);

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
  
  /*
  *
  */
  public void changeRange(JSONObject range){
    ObsScene current_scene = this.getCurrentScene();
    current_scene.tickLengthFrom = range.getFloat("from");
    current_scene.tickLengthTo = range.getFloat("to");
  }
  
  /*
  *
  */
  public void toggleSceneDetection(String name){
    ObsScene scene = this.getSceneByName(name);
    switch (PApplet.parseInt(scene.detection)) {
      case 1: scene.detection=false; break;
      case 0: scene.detection=true; break;
    }
  }
  
}
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
    }
    
    if (m.hasKey("toggle-source")) {
      bp.toggleSource(m.getString("toggle-source"));
    }
    
    if (m.hasKey("toggle-scene")) {
      bp.toggleScene(m.getString("toggle-scene"));
        this.sendScenes();
    }
    
    if (m.hasKey("change-range")) {
      bp.changeRange(m.getJSONObject("change-range"));
    }
    
    if (m.hasKey("toggle-scene-detection")) {
      bp.toggleSceneDetection(m.getString("toggle-scene-detection"));
      
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
  public void sendScenes() {
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
    System.out.println("Command Server: send Scenes" );
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
}
/* 
    OBS Remote Connection Draft Extension
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
/*
    The Websocket Client for OBS Remote
*/
public class ObsClient extends WebSocketClient {

  public boolean debug_message = false;
  
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
        s.sendScenes();
      }
      
      // source changed
      if(m.hasKey("source-name")){
        JSONObject source = m.getJSONObject("source");
        bp.setSourceRender(bp.currentScene, m.getString("source-name"), source.getBoolean("render"));
        //s.sendScenes();
      }    
    }

    // build scenes and sources
    if (m.hasKey("scenes")) {
      JSONArray scenes = m.getJSONArray("scenes");

      bp.obsScenesList = new ArrayList<ObsScene>();

      for (int i=0; i<scenes.size (); i++) {
        JSONObject scene    = scenes.getJSONObject(i);
        JSONArray sources   = scene.getJSONArray("sources");
        String scene_name   = scene.getString("name");

        bp.obsScenesList.add(i, new ObsScene(scene_name));

        ObsScene obsScene = bp.obsScenesList.get(i);

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
    System.out.println( "Connection closed by " + ( remote ? "remote peer" : "us" ) );
  }

  @Override
  public void onError( Exception ex ) {
    ex.printStackTrace();
    // if the error is fatal then onClose will be called additionally
  }
}
/*
    OBS Remote Scene
*/
public class ObsScene {

  public ArrayList<ObsSource> sources;
  private String name;
  public boolean detection = true;
  public boolean beat = true;
  public float tickLengthFrom = 0.1f; 
  public float tickLengthTo   = 5;

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
  
  public ObsSource getSourceByName(String name){
    for(int i=0; i<this.sources.size(); i++){
      if(this.sources.get(i).name.equals(name)){
        return this.sources.get(i);
      }
    }
    return new ObsSource("empty",false);
  }
  
  public int countBeatSources(){
    int count = 0;
    for(int i=0; i<this.sources.size(); i++){
      if(this.sources.get(i).beat==true){
        count++;
      }
    }
    return count;
  }
  
}
/*
    OBS Remote Source
*/
public class ObsSource {

  private String name = "";
  private Boolean render = true;
  private Boolean beat = true;

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
  
  public Boolean getBeat(){
    return beat;
  }
  
  
}
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
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "beatsocket" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
