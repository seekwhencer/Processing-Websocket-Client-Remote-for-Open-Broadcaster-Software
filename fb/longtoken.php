<?php

    require 'config.php';
    
    $long_token_json = implode(file('log/token'));
    $long_token = json_decode($long_token_json,true);
    
    if($long_token['access_token']){
        $conf['access_token'] = $long_token['access_token'];
    }
    
    
    require __DIR__ . '/sdk/autoload.php';   
    
    use Facebook\FacebookSession;
    use Facebook\FacebookRequest;
    
    FacebookSession::setDefaultApplication($conf['app_id'], $conf['app_secret']);
    $session = new FacebookSession($conf['access_token']);    
    
    
    $fh = fopen('log/get/longtoken','w+');
    fwrite($fh,json_encode($_GET));
    fclose($fh);
    
    $fh = fopen('log/post/longtoken','w+');
    fwrite($fh,json_encode($_POST));
    fclose($fh);
    
    
    // To validate the session:
    try {
      $session->validate();
    } catch (FacebookRequestException $ex) {
      // Session not valid, Graph API returned an exception with the reason.
      echo $ex->getMessage();
    } catch (\Exception $ex) {
      // Graph API returned info, but it may mismatch the current app or have expired.
      echo $ex->getMessage();
    }
    
    
    $request_uri = '/oauth/client_code?access_token='.$conf['access_token'].'&client_id='.$conf['app_id'].'&client_secret='.$conf['app_secret'].'&redirect_uri='.('http://fb.seekwhencer.de/');
    $request = new FacebookRequest($session,'GET',$request_uri);
    $response = $request->execute();
    $graphObject = $response->getGraphObject()->asArray();
    
    $fh = fopen('log/longtoken','w+');
    fwrite($fh,json_encode($graphObject));
    fclose($fh);
   
    
?>
<pre><?= print_r($graphObject,true); ?></pre>
<a href="comments.php" target="_parent">Get Comments</a>
