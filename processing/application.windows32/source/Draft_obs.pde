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
