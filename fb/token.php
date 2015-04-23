<?php
    
    require 'config.php';
    
    if($_GET['access_token']){
        $conf['access_token'] = $_GET['access_token'];
    }

    require __DIR__ . '/sdk/autoload.php';   
    
    use Facebook\FacebookSession;
    use Facebook\FacebookRequest;
    
    FacebookSession::setDefaultApplication($conf['app_id'], $conf['app_secret']);
    $session = new FacebookSession($conf['access_token']);
        
    
    $fh = fopen('log/get/token','w+');
    fwrite($fh,json_encode($_GET));
    fclose($fh);
    
    $fh = fopen('log/post/token','w+');
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
    
    
    
    //$request_uri = '/oauth/access_token?client_id='.$conf['app_id'].'&client_secret='.$conf['app_secret'].'&grant_type=client_credentials';
    $request_uri = '/oauth/access_token?client_id='.$conf['app_id'].'&client_secret='.$conf['app_secret'].'&grant_type=fb_exchange_token&fb_exchange_token='.$conf['access_token'];
    
    $request = new FacebookRequest($session,'GET',$request_uri);
    $response = $request->execute();
    $graphObject = $response->getGraphObject()->asArray();
    
    $fh = fopen('log/token','w+');
    fwrite($fh,json_encode($graphObject));
    fclose($fh);
    
   
    
?>
<? if($_GET['access_token']) :?>
<strong>Given Access Token</strong>
<?= $_GET['access_token']; ?>
<hr />
<? endif; ?>

<strong>Generate Long Token</strong>
<pre><?= print_r($graphObject,true); ?></pre>

<? if($graphObject['access_token']) : ?>
    <hr />
    <strong>Activate Long Token</strong>
    <iframe width="100%" height="200" src="longtoken.php" frameborder="0"></iframe>
<? endif; ?>

