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
