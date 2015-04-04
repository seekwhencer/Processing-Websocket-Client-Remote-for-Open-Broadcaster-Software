import spacebrew.*;
import java.net.URI;
import java.net.URISyntaxException;

// import java-websocket stuff
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

import org.json.*; //https://github.com/agoransson/JSON-processing


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
ObsClient c;

// 
int tickLo = 0;
int tickMid = 0;
int tickHi = 0;

float msLo   = 0;
float msMid  = 0;
float msHi   = 0;

float msLoLast   = 0;
float msMidLast  = 0;
float msHiLast   = 0;

String obsRemoteHost  = "localhost";
String obsRemotePort  = "4444";
String obsRemoteUrl   = "ws://"+obsRemoteHost+":"+obsRemotePort;
String obsRemoteMessage = "WS INIT";
String[] obsSources = {
  "src1", "src2", "src3"
};  
String[] obsScenes = { 
  "scn1", "scn2", "scn3", "scn4", "scn5"
};

// use "source" or "scene"
String obsRemoteSourceMode = "source";

int obsTickLast;
float obsTickLengthFrom = 0.1; 
float obsTickLengthTo = 5;

void setup() {
  size(240, 280);
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
}

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
    rect(10, 10, width-20, 50);
    tickLo++;
    msLo = millis() - msLoLast;
    msLoLast = millis();
    c.switchObsSource("src1");
  }

  if (snare == true) {
    fill(255, 0, 255);
    rect(10, 70, width-20, 50);
    tickMid++;
    msMid = millis()-msMidLast;
    msMidLast = millis();
    c.switchObsSource("src2");
  }


  if (hat == true) {
    fill(255);
    rect(10, 130, width-20, 50);
    tickHi++;
    msHi = millis()-msHiLast;
    msHiLast = millis();
    c.switchObsSource("src3");
  }

  fill( 0, 0, 0, 100 );
  rect(10, 200, width-20, 30);
  fill (150);

  text("Lo "+tickLo+" ("+msLo/1000+" sec.)", 10, 200);
  text("Mid " +tickMid+" ("+msMid/1000+" sec.)", 10, 230);
  text("Hi "+tickHi+" ("+msHi/1000+" sec.)", 10, 260);
}


void stop() {
  minim.stop();
  super.stop();
}



//
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

// Open Broadcaster Draft
public class Draft_obs extends Draft_17 {
  @Override
    public ClientHandshakeBuilder postProcessHandshakeRequestAsClient( ClientHandshakeBuilder request ) {
    super.postProcessHandshakeRequestAsClient( request );
    request.put( "Sec-WebSocket-Version", "13" );
    request.put( "Sec-WebSocket-Protocol", "obsapi" );
    return request;
  }
}

// The Client
public class ObsClient extends WebSocketClient {

  public ObsClient( URI serverUri, Draft draft ) {
    super( serverUri, draft );
  }

  public ObsClient( URI serverURI ) {
    super( serverURI );
  }

  public void switchObsSource(String source) {
    float diffTickLast = millis() - obsTickLast;
    float randMaxLast = random(obsTickLengthFrom, obsTickLengthTo)*1000;

    if (diffTickLast<randMaxLast)
      return;
    
    if(obsRemoteSourceMode=="source"){
      source = obsSources[int(random(obsSources.length))];
      c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+source+"\",\"render\":true}");
      this.offObsSource(source);
    }
    
    
    if(obsRemoteSourceMode=="scene"){
      source = obsScenes[int(random(obsScenes.length))];
      c.send("{\"request-type\":\"SetCurrentScene\",\"scene-name\":\""+source+"\"}");
    }

    

    obsTickLast = millis();
  }

  //turn all sources off
  public void offObsSource(String source) {
    for (String i : obsSources) {
      if (i!=source) {
        c.send("{\"request-type\":\"SetSourceRender\",\"source\":\""+i+"\",\"render\":false}");
      }
    }
  }

  @Override
    public void onOpen( ServerHandshake handshakedata ) {
    System.out.println( "opened connection" );
    // if you plan to refuse connection based on ip or httpfields overload: onWebsocketHandshakeReceivedAsClient
  }

  @Override
    public void onMessage( String message ) {
    //System.out.println( "received: " + message );
  }

  //@Override
  //public void onFragment( Framedata fragment ) {
  //  System.out.println( "received fragment: " + new String( fragment.getPayloadData().array() ) );
  //}

  @Override
    public void onClose( int code, String reason, boolean remote ) {
    // The codecodes are documented in class org.java_websocket.framing.CloseFrame
    System.out.println( "Connection closed by " + ( remote ? "remote peer" : "us" ) );
  }

  @Override
    public void onError( Exception ex ) {
    ex.printStackTrace();
    // if the error is fatal then onClose will be called additionally
  }
}

