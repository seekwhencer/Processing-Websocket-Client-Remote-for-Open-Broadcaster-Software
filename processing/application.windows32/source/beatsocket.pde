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
BeatPilot bp;


//
String obsRemoteHost  = "localhost";
String obsRemotePort  = "4444";
String obsRemoteUrl   = "ws://"+obsRemoteHost+":"+obsRemotePort;

String commandServerPort = "5555";


////////////////////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
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
void stop() {
  minim.stop();
  super.stop();
}
